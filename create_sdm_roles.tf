# ---------------------------------------------------------------------------- #
# Create an admin role with permissions to all resources
# ---------------------------------------------------------------------------- #
resource "sdm_role" "admins" {
  name = "${var.prefix}-admin-role"
}
resource "sdm_account" "admin_users" {
  count = length(var.admin_users)
  user {
    first_name = split("@", var.admin_users[count.index])[0]
    last_name = split("@", var.admin_users[count.index])[0]
    email = var.admin_users[count.index]
  }
}
resource "sdm_account_attachment" "admin_attachment" {
  count = length(var.admin_users)
  account_id = sdm_account.admin_users[count.index].id
  role_id = sdm_role.admins[0].id
}
# ---------------------------------------------------------------------------- #
# Add existing users to admin role
# ---------------------------------------------------------------------------- #
data "sdm_account" "existing_users" {
  count = length(var.grant_to_existing_users)
  type = "user"
  email = var.grant_to_existing_users[count.index]
}
resource "sdm_account_attachment" "existing_users" {
  count = length(var.grant_to_existing_users)
  account_id = element(data.sdm_account.existing_users[count.index].ids, 0)
  role_id = sdm_role.admins[0].id
}

# ---------------------------------------------------------------------------- #
# Create a limited access role with read only permissions
# ---------------------------------------------------------------------------- #
resource "sdm_role" "read_only" {
  name = "${var.prefix}-read-only-role"
}
resource "sdm_account" "read_only_users" {
  count = length(var.read_only_users)
  user {
    first_name = split("@", var.read_only_users[count.index])[0]
    last_name = split("@", var.read_only_users[count.index])[0]
    email = var.read_only_users[count.index]
  }
}
resource "sdm_account_attachment" "read_only_attachment" {
  count = length(var.read_only_users) 
  account_id = sdm_account.read_only_users[count.index].id
  role_id = sdm_role.read_only[0].id
}
