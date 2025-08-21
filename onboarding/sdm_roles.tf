# =============================================================================
# STRONGDM ROLES AND USER MANAGEMENT
# =============================================================================
# This file manages StrongDM roles, user accounts, and access assignments
# for the onboarding module. It creates admin roles with broad permissions
# and manages user account creation and role assignments.
#
# Security Model:
#   - Tag-based access control using "CreatedBy" tag matching
#   - Admin users receive access to all onboarding-created resources
#   - Automatic user provisioning from email addresses
#   - Role attachments for both new and existing users
#
# Role Structure:
#   - Admin Role: Full access to all resources with onboarding tag
#   - Read-only Role: View-only access for auditing and monitoring
#   - Resource-specific access via StrongDM's tag matching system
# =============================================================================

# -----------------------------------------------------------------------------
# ADMIN ROLE CONFIGURATION
# -----------------------------------------------------------------------------
# Creates administrative role with access to all onboarding-created resources
# Uses tag-based access control for automatic resource inclusion

resource "sdm_role" "admins" {
  name = "${var.name}-admin-role"

  # Tag-based access rule granting access to all onboarding resources
  # Resources created by this module are automatically tagged with "CreatedBy = strongDM-Onboarding"
  # This rule grants admin role access to any resource matching this tag
  access_rules = jsonencode([
    {
      tags = {
        CreatedBy = "strongDM-Onboarding"
      }
    }
  ])
}

# -----------------------------------------------------------------------------
# ADMIN USER ACCOUNT CREATION
# -----------------------------------------------------------------------------
# Creates new StrongDM user accounts for specified admin email addresses
# Users are automatically granted administrative privileges

resource "sdm_account" "admin_users" {
  count = length(var.admin_users)

  user {
    # Extract username from email address for first name
    # Example: "admin@company.com" becomes first_name = "admin"
    first_name = split("@", var.admin_users[count.index])[0]
    last_name  = "Onboarding" # Standard last name for onboarding users
    email      = var.admin_users[count.index]
  }
}

# -----------------------------------------------------------------------------
# ADMIN ROLE ASSIGNMENTS
# -----------------------------------------------------------------------------
# Assigns newly created admin users to the admin role

resource "sdm_account_attachment" "admin_attachment" {
  count      = length(var.admin_users)
  account_id = sdm_account.admin_users[count.index].id
  role_id    = sdm_role.admins.id
}

# -----------------------------------------------------------------------------
# EXISTING USER ROLE ASSIGNMENTS  
# -----------------------------------------------------------------------------
# Grants admin role access to existing StrongDM users specified by email
# These users must already exist in the StrongDM organization

resource "sdm_account_attachment" "existing_users" {
  count      = length(var.grant_to_existing_users)
  account_id = element(data.sdm_account.existing_users[count.index].ids, 0)
  role_id    = sdm_role.admins.id
}

# ---------------------------------------------------------------------------- #
# Create a limited access role with read only permissions
# ---------------------------------------------------------------------------- #
resource "sdm_role" "read_only" {
  name = "${var.name}-read-only-role"
  access_rules = jsonencode([
    { tags = { ReadOnlyOnboarding = "true" } }
  ])
}
resource "sdm_account" "read_only_users" {
  count = length(var.read_only_users)
  user {
    first_name = split("@", var.read_only_users[count.index])[0]
    last_name  = split("@", var.read_only_users[count.index])[0]
    email      = var.read_only_users[count.index]
  }
}
resource "sdm_account_attachment" "read_only_attachment" {
  count      = length(var.read_only_users)
  account_id = sdm_account.read_only_users[count.index].id
  role_id    = sdm_role.read_only.id
}

resource "sdm_policy" "permit_everything" {
  count = var.create_sdm_policy_permit_everything ? 1 : 0

  name        = "permit-everything"
  description = "Permits everything"

  policy = <<EOP
permit(principal, action, resource);
EOP
}
