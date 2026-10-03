# Protected Generated Configuration Delivery

GDQ's strict main ruleset rejects direct generated-file writes. The general
module therefore targets `terraform/generated-config` for every GDQ-managed
repository file. All other repositories retain their existing delivery path.
Terraform owns staged bytes; a normal PR delivers them to protected main.
The ruleset and required checks are unchanged.

The manifest in `tools/gdq-generated-files.json` must match the authoritative
templates. Regenerate it with `tools/generated-config.mjs` when templates
change; CI checks exact output. Trusted policy validation accepts a deployment
wrapper change only when every changed path and byte matches this manifest at
the current trusted `mahn-ke/repos` main revision. Branch names and PR markers
alone never authorize a merge.

## Initial State Adoption

The GitHub provider treats a file's branch change as replacement. Do not apply
that replacement: it would attempt to delete a main-branch file. Instead:

1. Merge the shared policy/hooks before the repos generator change. The hooks
   skip old repos revisions lacking the delivery helper.
2. Stop competing repos deployments through normal workflow cancellation and
   confirm Terraform is idle. Never force-unlock an active workspace.
3. Dispatch `Adopt protected generated configuration state` on repos main and
   approve its production gate. This creates or safely refreshes the staging
   branch, backs up state with mode 0600 in the runner temporary directory,
   then forgets and reimports only GDQ file identities at their existing
   addresses. Remote files are not deleted. The branch identity is imported
   separately. State snapshots are sensitive and must never be uploaded.
4. If an import fails after state removal, stop. Use the saved snapshot and
   exact address to restore the association by import; do not run a broad apply.
   The old main file remains intact. The workflow can retry missing adoption
   only after verifying current state and the matching staging copy.
5. Run a new current-main deployment, review the plan for no GDQ main-file
   replacement/deletion, approve its production apply, and review the generated
   PR. Main builds refuse legacy main-file state until adoption is done.

The staging branch may be deleted after merge. The next main build recreates it
from current main; Terraform refreshes missing branch/file identities normally.
When a stale owned branch has commits, only known generated paths are allowed
and main is merged without force-pushing. Conflicts or unrelated edits fail
closed. Publisher verifies actual changed bytes, skips empty diffs, and updates
one existing generated PR rather than creating duplicates.

## Verification

- Run `node --test tools/generated-config*.test.mjs`, Terraform formatting and
  backend-free validation, and actionlint for adoption and shared workflows.
- Confirm all generated GDQ paths route to staging and other repositories have
  no delivery change. No ruleset bypass actors are added.
- Confirm state adoption changes only GDQ file/branch associations, never files
  on main. Review a fresh plan instead of replaying an old saved plan.
- Require normal build, both plans, setup, and Infrastructure review before
  merging the generated PR. Check a second cycle produces no duplicate PR or
  repeated generated diff.

The adoption workflow is a one-off migration tool, not an automatic state edit
on every PR. Generator output must be refreshed whenever templates change;
the manifest consistency test intentionally fails until it is updated.