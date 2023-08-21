import { isLocationSharesActive, isLocationSpacesActive } from '../../router'
import isFilesAppActive from './helpers/isFilesAppActive'
import isSearchActive from '../helpers/isSearchActive'
import { mapActions } from 'vuex'
import { urlJoin } from 'web-client/src/utils'
import { stringify } from 'qs'
import { configurationManager } from 'web-pkg/src/configuration'

export default {
  mixins: [isFilesAppActive, isSearchActive],
  computed: {
    $_exportToOverleaf() {
      return [
        {
          name: 'export-to-overleaf',
          icon: 'overleaf',
          handler: this.$_exportToOverleaf_trigger,
          label: () => {
            return this.$gettext('Export to Overleaf')
          },
          isEnabled: ({ resources }) => {
            if (
              resources.length === 1 &&
              (resources[0].isFolder === true ||
                resources[0].mimeType == "application/x-tex")
            ) {
              return true
            }
            return false
          },
          canBeDefault: true,
          componentType: 'button',
          class: 'oc-files-actions-export-to-overleaf'
        }
      ]
    }
  },
  methods: {
    ...mapActions(['showMessage']),

    $_exportToOverleaf_trigger({ resources }) {
      this.exportToOverleaf(resources[0])
    },

    async exportToOverleaf (resource) {
      const baseUrl = urlJoin(
        configurationManager.serverUrl,
        "overleaf/export"
      )
      const accessToken = this.$store.getters['runtime/auth/accessToken']
      const headers = new Headers()
      headers.append('Authorization', 'Bearer ' + accessToken)
      headers.append('X-Requested-With', 'XMLHttpRequest')
      headers.append('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')

      const query = stringify({
        path: resource.path,
        lang: this.$language.current
      })
      const url = `${baseUrl}?${query}`

      const response = await fetch(url, {
        method: 'POST',
        headers,
      })
      const res = await response.json()

      if (res.app_url && response.ok) {
        const win = window.open(res.app_url, '_blank')
        // in case popup is blocked win will be null
        if (win) {
          win.focus()
        } else {
          this.showMessage({
            title: this.$gettext('Blocked pop-ups and redirects'),
            timeout: 10,
            status: 'warning',
            desc: this.$gettext(
              'Some features might not work correctly. Please enable pop-ups and redirects in Settings > Privacy & Security > Site Settings > Permissions'
            )
          })
        }
      } else {
        // Overleaf conflict: project already exported
        if (res.code == "ALREADY_EXISTS") {
          var message = "Project already exported."
          if (res.export_time){
            const date = new Date(res.export_time * 1000)
            const readableDate = date.getFullYear() +
              '-' +
              String(date.getMonth() + 1).padStart(2, '0') +
              '-' +
              String(date.getDate()).padStart(2, '0') +
              ' at ' +
              String(date.getHours()).padStart(2, '0') +
              ":" +
              String(date.getMinutes()).padStart(2, '0')
            message = "Project already exported on "+readableDate
          }
          const modal = {
            variation: 'warning',
            title: message,
            cancelText: this.$gettext('Cancel'),
            confirmText: this.$gettext('Export'),
            message: this.$gettext('Would you like to export this project again? This will create a new Overleaf project.'),
            hasInput: false,
            onCancel: this.hideModal,
            onConfirm: () => this.retryRequest(url, headers),
          }
          this.createModal(modal)

        } else {
          var error_message = "Unable to export project"
          // Display error message returned in request
          if (res.message != ""){
            error_message += ": "+res.message
          }

          this.showMessage({
            title: this.$gettext('An error occured'),
            timeout: 10,
            status: 'danger',
            desc: this.$gettext(error_message)
          })
        }
      }
    },

    async retryRequest (url, headers) {
      this.hideModal()

      const additional_params = stringify({
        override: "true"
      })

      const retryUrl = `${url}&${additional_params}`

      const response = await fetch(retryUrl, {
        method: 'POST',
        headers,
      })

      const res = await response.json()

      if (res.app_url && response.ok) {
        const win = window.open(res.app_url, '_blank')
        // in case popup is blocked win will be null
        if (win) {
          win.focus()
        } else {
          this.showMessage({
            title: this.$gettext('Blocked pop-ups and redirects'),
            timeout: 10,
            status: 'warning',
            desc: this.$gettext(
              'Some features might not work correctly. Please enable pop-ups and redirects in Settings > Privacy & Security > Site Settings > Permissions'
            )
          })
        }
      } else {
        var error_message = "Unable to export project"
        // Display error message returned in request
        if (res.message != ""){
          error_message += ": "+res.message
        }

        this.showMessage({
          title: this.$gettext('An error occured'),
          timeout: 10,
          status: 'danger',
          desc: this.$gettext(error_message)
        })
      }
    }
  }
}
