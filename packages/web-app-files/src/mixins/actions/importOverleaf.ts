import { isLocationTrashActive, isLocationSharesActive } from '../../router'
import { ShareStatus } from 'web-client/src/helpers/share'
import isFilesAppActive from './helpers/isFilesAppActive'
import isSearchActive from '../helpers/isSearchActive'
import { isSameResource } from '../../helpers/resource'
import { mapActions } from 'vuex'
import { urlJoin } from 'web-client/src/utils'
import { stringify } from 'qs'
import { configurationManager } from 'web-pkg/src/configuration'

export default {
  mixins: [isFilesAppActive, isSearchActive],
  computed: {
    $_importFromOverleaf() {
      return [
        {
          name: 'import-from-overleaf',
          icon: 'overleaf',
          handler: this.$_importFromOverleaf_trigger,
          label: () => {
            return this.$gettext('Re-import from Overleaf')
          },
          isEnabled: ({ resources }) => {
            if (isLocationTrashActive(this.$router, 'files-trash-generic')) {
              return false
            }

            if (this.currentFolder !== null && isSameResource(resources[0], this.currentFolder)) {
              return false
            }

            if (
              isLocationSharesActive(this.$router, 'files-shares-with-me') &&
              resources[0].status === ShareStatus.declined
            ) {
              return false
            }

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
          class: 'oc-files-actions-import-to-overleaf'
        }
      ]
    }
  },
  methods: {
    ...mapActions(['showMessage']),

    $_importFromOverleaf_trigger({ resources }) {
      this.importFromOverleaf(resources[0])
    },

    async importFromOverleaf (resource) {
      const modal = {
        variation: 'warning',
        title: "Import from Overleaf",
        cancelText: this.$gettext('Cancel'),
        confirmText: this.$gettext('Overwrite Project'),
        message: this.$gettext('Importing this project back from Overleaf will overwrite the contents of this resource. Would you still like to proceed?'),
        hasInput: false,
        onCancel: this.hideModal,
        onConfirm: () => this.makeRequest(resource, false),
      }
      this.createModal(modal)
    },

    async makeRequest (resource, forceImport) {
      this.hideModal()

      const baseUrl = urlJoin(
        configurationManager.serverUrl,
        "overleaf/import"
      )
      const accessToken = this.$store.getters['runtime/auth/accessToken']
      const headers = new Headers()
      headers.append('Authorization', 'Bearer ' + accessToken)
      headers.append('X-Requested-With', 'XMLHttpRequest')
      headers.append('Content-Type', 'application/x-www-form-urlencoded; charset=UTF-8')

      const query = stringify({
        path: resource.path,
        lang: this.$language.current,
        ...(forceImport==true && { force_import: forceImport })
      })
      const url = `${baseUrl}?${query}`

      const response = await fetch(url, {
        method: 'GET',
        headers,
      })

      if(response.status == 200) {
        this.showMessage({
          title: this.$gettext('Import success'),
          timeout: 10,
          status: 'success',
          desc: "Overleaf project was imported successfully"
        })
      } else {
        const res = await response.json()
        if (res.message == "Multiple files detected in project when importing into a single file") {
          const modal = {
            variation: 'warning',
            title: "Import from Overleaf",
            cancelText: this.$gettext('Cancel'),
            confirmText: this.$gettext('Import to current folder'),
            message: this.$gettext('Mutliple files detected in project folder. Would you like to import them in this directory?'),
            hasInput: false,
            onCancel: this.hideModal,
            onConfirm: () => this.makeRequest(resource, true),
          }
          this.createModal(modal)
        } else {
          var error_message = "An error occured when trying to import the project"
          if (res.message != ""){
            error_message = res.message
          }

          this.showMessage({
            title: this.$gettext('Error importing project from Overleaf'),
            timeout: 10,
            status: 'danger',
            desc: this.$gettext(error_message)
          })
        }
      }
    }

  }
}
