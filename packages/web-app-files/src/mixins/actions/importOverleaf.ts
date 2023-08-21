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
    $_importFromOverleaf() {
      return [
        {
          name: 'import-from-overleaf',
          icon: 'overleaf',
          handler: this.$_importFromOverleaf_trigger,
          label: () => {
            return this.$gettext('Import from Overleaf')
          },
          isEnabled: ({ resources }) => {
            if (
              resources.length === 1 &&
              resources[0].isFolder === true
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
        message: this.$gettext('Importing this project back from Overleaf will overwrite the current contents of this folder. Would you still like to proceed?'),
        hasInput: false,
        onCancel: this.hideModal,
        onConfirm: () => this.makeRequest(resource),
      }
      this.createModal(modal)
    },

    async makeRequest (resource) {
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
        lang: this.$language.current
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
