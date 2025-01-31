import { Store } from 'vuex'
interface Permission {
  description: string
  displayName: string
  id: string
  name: string
  permissionValue: {
    constraint: string
    operation: string
  }
  resource: {
    id: string
    type: string
  }
}
export enum UserRoleName {
  Admin = 'admin',
  SpaceAdmin = 'spaceadmin',
  User = 'user',
  Guest = 'guest'
}
interface UserRole {
  name: UserRoleName
  settings: Array<Permission>
}
interface User {
  role: UserRole
}

export class PermissionManager {
  private readonly store: Store<any>

  constructor(store: Store<any>) {
    this.store = store
  }

  public hasSystemManagement() {
    return this.user.role?.name === UserRoleName.Admin
  }

  public hasUserManagement() {
    return this.user.role?.name === UserRoleName.Admin
  }

  public hasSpaceManagement() {
    return [UserRoleName.Admin, UserRoleName.SpaceAdmin].includes(this.user.role?.name)
  }

  public canEditSpaceQuota() {
    return !!this.user.role?.settings.find((s) => s.name === 'set-space-quota')
  }

  get user(): User {
    return this.store.getters.user
  }
}
