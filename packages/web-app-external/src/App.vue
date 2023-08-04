<template>
  <main
    class="oc-height-1-1"
    :class="{
      'oc-flex oc-flex-center oc-flex-middle': loading || loadingError
    }"
  >
    <oc-modal
      v-if="modal"
      :icon="'alarm-warning'"
      :title="'Microsoft debug'"
      :button-cancel-text="'Cancel'"
      :button-confirm-text="'Force reload'"
      @cancel="
        () => {
          modal = false
        }
      "
      @confirm="
        () => {
          debugMicrosoft = true
          modal = false
        }
      "
    >
      <template #content>
        <p>If you are facing problems with editing the document, please force reload</p>
        <p>
          OTG:
          <a href="https://cern.service-now.com/service-portal?id=outage&n=OTG0074523"
            >OTG0074523</a
          >
        </p>
      </template>
    </oc-modal>
    <h1 class="oc-invisible-sr" v-text="pageTitle" />
    <loading-screen v-if="loading" />
    <error-screen v-else-if="loadingError" :message="errorMessage" />
    <iframe
      v-if="appUrl && method === 'GET'"
      :src="appUrl"
      class="oc-width-1-1 oc-height-1-1"
      :title="iFrameTitle"
      allowfullscreen
    />
    <div v-if="appUrl && method === 'POST' && formParameters" class="oc-height-1-1">
      <form :action="appUrl" target="app-iframe" method="post">
        <input ref="subm" type="submit" :value="formParameters" class="oc-hidden" />
        <div v-for="(item, key, index) in formParameters" :key="index">
          <input :name="key" :value="item" type="hidden" />
        </div>
      </form>
      <iframe
        name="app-iframe"
        class="oc-width-1-1 oc-height-1-1"
        :title="iFrameTitle"
        allowfullscreen
      />
    </div>
  </main>
</template>

<script lang="ts">
import { mapActions, mapGetters } from 'vuex'
import ErrorScreen from './components/ErrorScreen.vue'
import LoadingScreen from './components/LoadingScreen.vue'
import { computed, unref } from 'vue'
import { queryItemAsString, useAppDefaults, useRouteQuery } from 'web-pkg/src/composables'
import { defineComponent } from 'vue'
import { DavProperty } from 'web-client/src/webdav/constants'
import { urlJoin } from 'web-client/src/utils'
import { stringify } from 'qs'
import { configurationManager } from 'web-pkg/src/configuration'

export default defineComponent({
  name: 'ExternalApp',

  components: {
    ErrorScreen,
    LoadingScreen
  },
  setup() {
    const appName = useRouteQuery('app')
    const applicationName = computed(() => queryItemAsString(unref(appName)))
    return {
      ...useAppDefaults({
        applicationId: 'external',
        applicationName
      }),
      applicationName
    }
  },

  data: () => ({
    loading: false,
    loadingError: false,
    errorMessage: '',
    appUrl: '',
    method: '',
    formParameters: {},
    debugMicrosoft: false,
    modal: false,
    viewmodeWrite: false,
    fileName: undefined,
    writePermissions: false,
    fileInfo: {},
    func: undefined,
    func2: undefined,
    events: []
  }),
  computed: {
    ...mapGetters(['capabilities']),

    pageTitle() {
      const translated = this.$gettext('"%{appName}" app page')
      return this.$gettextInterpolate(translated, {
        appName: this.applicationName
      })
    },
    iFrameTitle() {
      const translated = this.$gettext('"%{appName}" app content area')
      return this.$gettextInterpolate(translated, {
        appName: this.applicationName
      })
    },
    fileId() {
      return this.$route.query.fileId
    }
  },
  watch: {
    debugMicrosoft(n, o) {
      if (n === true) {
        this.onCreate(true)
      }
    }
  },
  async created() {
    await this.onCreate(false)
  },
  methods: {
    ...mapActions(['createModal', 'hideModal']),
    catchMicrosoftError() {
      this.events = []
      if (!this.func)
        this.func = (event) => {
          this.events.push(JSON.parse(event.data))
        }
      window.removeEventListener('message', this.func)
      if (
        window.location.href.includes('app=MS') &&
        this.writePermissions &&
        !this.debugMicrosoft
      ) {
        const timeInterval =
          (this.fileName && this.fileName.endsWith('.ppt')) ||
          this.fileName.endsWith('.pptx') ||
          this.fileName.endsWith('.odp')
            ? 13 * 1000
            : 7 * 1000
        window.addEventListener('message', this.func)

        setTimeout(() => {
          if (
            !this.events.some((e) => {
              return e.MessageId === 'App_LoadingStatus'
            })
          ) {
            this.modal = true
            setTimeout(() => {
              if (
                this.events.some((e) => {
                  return e.MessageId === 'App_LoadingStatus'
                })
              )
                this.modal = false
              window.removeEventListener('message', this.func)
            }, timeInterval)
          }
        }, timeInterval)
      }
    },
    async catchClickMicrosoftEdit() {
      if (!this.func2)
        this.func2 = async (event) => {
          if (JSON.parse(event.data).MessageId === 'UI_Edit') {
            await this.onCreate(true)
            this.catchMicrosoftError()
          }
        }
      window.removeEventListener('message', this.func2)
      window.addEventListener('message', await this.func2)
    },
    async onCreate(editMode) {
      this.loading = true
      try {
        if (!editMode)
          this.fileInfo = await this.getFileInfo(this.currentFileContext, {
            davProperties: [DavProperty.FileId, DavProperty.Permissions, DavProperty.Name]
          })
        const fileId = this.fileId || this.fileInfo.fileId
        this.fileName = this.fileInfo.name
        this.writePermissions = this.fileInfo.permissions.includes('W')

        // fetch iframe params for app and file
        const baseUrl = urlJoin(
          configurationManager.serverUrl,
          this.capabilities.files.app_providers[0].open_url
        )

        const viewMode = editMode
          ? 'write'
          : this.fileInfo.isReceivedShare() ||
            window.location.pathname.startsWith('/external/public/')
          ? 'preview'
          : false

        const query = stringify({
          file_id: fileId,
          lang: this.$language.current,
          ...(this.applicationName && { app_name: this.applicationName }),
          ...(this.debugMicrosoft && { forcelock: 1 }),
          ...(viewMode && { view_mode: viewMode }),
        })
        const url = `${baseUrl}?${query}`
        const response = await this.makeRequest('POST', url, {
          validateStatus: () => true
        })

        if (response.status !== 200) {
          switch (response.status) {
            case 425:
              this.errorMessage = this.$gettext(
                'This file is currently being processed and is not yet available for use. Please try again shortly.'
              )
              break
            case 403:
            if(this.applicationName == "Overleaf"){
                // Extracting time from error message and converting it to local time to a readable format from unix format
                const startTime = "Project was already exported on:"
                const unixTime = response.data?.message.slice(response.data?.message.indexOf(startTime) + startTime.length);
                const date = new Date(unixTime * 1000)

                const readableDate = date.getFullYear() +
                    '-' +
                    String(date.getMonth() + 1).padStart(2, '0') +
                    '-' +
                    String(date.getDate()).padStart(2, '0') +
                    ' at ' +
                    String(date.getHours()).padStart(2, '0') +
                    ":" +
                    String(date.getMinutes()).padStart(2, '0')

                const modal = {
                  variation: 'warning',
                  title: this.$gettext('Project was already exported on') + " " + readableDate + ".",
                  cancelText: this.$gettext('Cancel'),
                  confirmText: this.$gettext('Export'),
                  message: this.$gettext('Would you like to export this project again? This will create a new Overleaf project.'),
                  hasInput: false,
                  onCancel: this.hideModal,
                  onConfirm: (e = editMode, u = url) => this.retryQuery(e, u),
                }

                this.createModal(modal)
                this.errorMessage = this.$gettext(
                  'This project has already been uploaded to Overleaf.'
                )
                break
              }
              // Otherwise we can keep default error message
            default:
              this.errorMessage = response.data?.message
          }

          this.loading = false
          this.loadingError = true
          console.error('Error fetching app information', response.status, response.data.message)
          return
        }

        this.handleResponse(response, editMode)

      } catch (error) {
        this.errorMessage = this.$gettext('Error retrieving file information')
        console.error('Error retrieving file information', error)
        this.loading = false
        this.loadingError = true
      }
    },

    async handleResponse(response, editMode) {
      if (!response.data.app_url || !response.data.method) {
        this.errorMessage = this.$gettext('Error in app server response')
        this.loading = false
        this.loadingError = true
        console.error('Error in app server response')
        return
      }

      switch (response.data.target) {
        case "iframe":
          // Target is an iframe
          this.appUrl = response.data.app_url
          this.method = response.data.method
          if (response.data.form_parameters) {
            this.formParameters = response.data.form_parameters
          }

          if (this.method === 'POST' && this.formParameters) {
            this.$nextTick(() => this.$refs.subm.click())
          }
          this.loading = false
          if (window.location.href.includes('app=MS')) {
            // if not file owner, wait for clicking "Edit" button in MS
            if (
              this.fileInfo.isReceivedShare() ||
              window.location.pathname.startsWith('/external/public/')
            ) {
              await this.catchClickMicrosoftEdit()
            }
            // if file owner, wait for success loading event and also wait for clicking "Edit"
            else {
              this.catchMicrosoftError()
              await this.catchClickMicrosoftEdit()
            }
          }
          break
        case "blank":
          // Target is none (open in new tab)
          const win = window.open(response.data.app_url, '_self')
          if (!win) {
            this.showMessage({
              title: this.$gettext('Blocked pop-ups and redirects'),
              timeout: 10,
              status: 'warning',
              desc: this.$gettext('Some features might not work correctly. Please enable pop-ups and redirects in Settings > Privacy & Security > Site Settings > Permissions')
            })
          }
          break
        default:
          // undefined target
          this.errorMessage = this.$gettext('Error in app server response')
          this.loading = false
          this.loadingError = true
          console.error('Error in app server response: invalid target')
      }
    },

    async retryQuery(editMode, url) {
      this.hideModal()
      this.loading = true

      const additional_params = stringify({
        override: "true"
      })

      const retry_url = `${url}&${additional_params}`
      const response = await this.makeRequest('POST', retry_url, {
        validateStatus: () => true
      })

      // In case of another error, display error message and quit. We only try to handle duplicates once
      if (response.status !== 200) {
        switch (response.status) {
          case 425:
            this.errorMessage = this.$gettext(
              'This file is currently being processed and is not yet available for use. Please try again shortly.'
            )
            break
          default:
            this.errorMessage = response.data?.message
        }

        this.loading = false
        this.loadingError = true
        console.error('Error fetching app information', response.status, response.data.message)
        return
      }

      this.handleResponse(response, editMode)
    }

  }
})
</script>
