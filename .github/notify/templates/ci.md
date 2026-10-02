**{{github.workflow}}: {{github.repository}}**

Status: **{{status_label}}**
Ref: `{{github.ref_name}}`
Triggered by: {{github.actor}}

[Open workflow run]({{url github.run_url}})
{{#if pub_dev_url}}
[Open package on pub.dev]({{url pub_dev_url}})
{{/if}}
