export const DefaultRoles = {
  Elder: 'elder',
  Caregiver: 'caregiver',
  Youth: 'youth',
  Admin: 'admin',
} as const;

export const DefaultPermissions = {
  ReadProfile: 'profile:read',
  WriteProfile: 'profile:write',
  ReadVitals: 'vitals:read',
  WriteVitals: 'vitals:write',
  ReadMeds: 'meds:read',
  WriteMeds: 'meds:write',
  ReadAppointments: 'appointments:read',
  WriteAppointments: 'appointments:write',
  ManageUsers: 'users:manage',
  BreakGlass: 'emergency:override',
} as const;

export type Role = typeof DefaultRoles[keyof typeof DefaultRoles];
export type Permission = typeof DefaultPermissions[keyof typeof DefaultPermissions];

export class RBAC {
  private rolePerms: Record<string, Set<string>>;

  constructor(rolePermissions?: Record<string, string[]>) {
    this.rolePerms = {};
    const base: Record<string, string[]> = rolePermissions ?? {
      [DefaultRoles.Elder]: [
        DefaultPermissions.ReadProfile,
        DefaultPermissions.WriteProfile,
        DefaultPermissions.ReadVitals,
        DefaultPermissions.ReadMeds,
        DefaultPermissions.ReadAppointments,
      ],
      [DefaultRoles.Caregiver]: [
        DefaultPermissions.ReadProfile,
        DefaultPermissions.ReadVitals,
        DefaultPermissions.WriteVitals,
        DefaultPermissions.ReadMeds,
        DefaultPermissions.WriteMeds,
        DefaultPermissions.ReadAppointments,
        DefaultPermissions.WriteAppointments,
      ],
      [DefaultRoles.Youth]: [DefaultPermissions.ReadProfile, DefaultPermissions.ReadAppointments],
      [DefaultRoles.Admin]: Object.values(DefaultPermissions),
    };
    for (const [role, perms] of Object.entries(base)) this.rolePerms[role] = new Set(perms);
  }

  can(role: Role, permission: Permission): boolean {
    const set = this.rolePerms[role];
    if (!set) return false;
    return set.has(permission);
  }
}

export function isOwner(actorId: string, ownerId: string): boolean {
  return actorId === ownerId;
}
