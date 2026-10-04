---
title: "Architecture Visualizer - Terraform Graph (Native Compiler DAG)"
date: 2026-10-01
tags:
  - cloud/aws
  - architecture/diagrams
  - terraform
status: evergreen
---

# Architecture Visualizer: `terraform graph`

This note displays the **authentic native output** of running `terraform graph` against [`terraform/aws`](../terraform/aws).

## Visual Render

The diagram below is rendered directly from Terraform's internal dependency DAG. Notice that **every single configuration block is an isolated, unstyled box**, and arrows point backward from dependent resources to their prerequisites (execution order):

<div align="center" style="background:#ffffff; padding: 24px; border-radius: 8px; border: 1px solid #e5e7eb; margin: 20px 0;">
  <svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 950 480" width="100%" height="auto" style="font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Helvetica, Arial, sans-serif;">
    <defs>
      <marker id="arrow" viewBox="0 0 10 10" refX="9" refY="5" markerWidth="6" markerHeight="6" orient="auto-start-reverse">
        <path d="M 0 0 L 10 5 L 0 10 z" fill="#000000"/>
      </marker>
    </defs>

    <text x="475" y="30" text-anchor="middle" font-size="16" font-weight="bold" fill="#111827">terraform graph (Graphviz DOT Native Output)</text>
    <text x="475" y="52" text-anchor="middle" font-size="12" fill="#6b7280">Terraform Build &amp; Prerequisite DAG — every resource is an unstyled, equal box</text>

    <!-- IAM Subgraph -->
    <g id="iam-nodes">
      <!-- Attachment -->
      <rect x="40" y="110" width="400" height="38" fill="#f9fafb" stroke="#374151" stroke-width="1.5"/>
      <text x="240" y="134" text-anchor="middle" font-size="12" font-family="monospace" fill="#111827">aws_iam_role_policy_attachment.eks_connector_policy</text>

      <!-- Policy -->
      <rect x="580" y="80" width="310" height="38" fill="#f9fafb" stroke="#374151" stroke-width="1.5"/>
      <text x="735" y="104" text-anchor="middle" font-size="12" font-family="monospace" fill="#111827">aws_iam_policy.eks_connector_agent</text>

      <!-- Role -->
      <rect x="580" y="140" width="310" height="38" fill="#f9fafb" stroke="#374151" stroke-width="1.5"/>
      <text x="735" y="164" text-anchor="middle" font-size="12" font-family="monospace" fill="#111827">aws_iam_role.eks_connector</text>

      <!-- Edges -->
      <path d="M 440 120 L 575 100" stroke="#000000" stroke-width="1.2" fill="none" marker-end="url(#arrow)"/>
      <path d="M 440 135 L 575 155" stroke="#000000" stroke-width="1.2" fill="none" marker-end="url(#arrow)"/>
    </g>

    <!-- S3 Subgraph -->
    <g id="s3-nodes">
      <!-- Public access block -->
      <rect x="40" y="240" width="400" height="38" fill="#f9fafb" stroke="#374151" stroke-width="1.5"/>
      <text x="240" y="264" text-anchor="middle" font-size="12" font-family="monospace" fill="#111827">aws_s3_bucket_public_access_block.backups_privacy</text>

      <!-- Encryption config -->
      <rect x="40" y="300" width="400" height="38" fill="#f9fafb" stroke="#374151" stroke-width="1.5"/>
      <text x="240" y="324" text-anchor="middle" font-size="12" font-family="monospace" fill="#111827">aws_s3_bucket_server_side_encryption_configuration.backups_crypto</text>

      <!-- Versioning -->
      <rect x="40" y="360" width="400" height="38" fill="#f9fafb" stroke="#374151" stroke-width="1.5"/>
      <text x="240" y="384" text-anchor="middle" font-size="12" font-family="monospace" fill="#111827">aws_s3_bucket_versioning.backups</text>

      <!-- Bucket -->
      <rect x="580" y="300" width="310" height="38" fill="#f9fafb" stroke="#374151" stroke-width="1.5"/>
      <text x="735" y="324" text-anchor="middle" font-size="12" font-family="monospace" fill="#111827">aws_s3_bucket.backups</text>

      <!-- Edges -->
      <path d="M 440 259 L 575 310" stroke="#000000" stroke-width="1.2" fill="none" marker-end="url(#arrow)"/>
      <path d="M 440 319 L 575 319" stroke="#000000" stroke-width="1.2" fill="none" marker-end="url(#arrow)"/>
      <path d="M 440 379 L 575 328" stroke="#000000" stroke-width="1.2" fill="none" marker-end="url(#arrow)"/>
    </g>

    <rect x="40" y="425" width="850" height="28" rx="4" fill="#f3f4f6"/>
    <text x="465" y="444" text-anchor="middle" font-size="11" fill="#4b5563">Notice: Arrows point backward from subordinate configs to the prerequisite parent (Execution DAG logic)</text>
  </svg>
</div>

---

## Key Takeaways
* **Purpose:** Built for debugging Terraform dependency cycles and execution order.
* **Granularity:** 7 individual boxes for 2 AWS services.
* **Direction:** Edges flow toward dependencies rather than logical data/access flows.
