# notify

Tiny composite GitHub Action that just notifies me when an event occurs

### Inputs
- `token` **required** — secret needed
- `type` **required** - enumerable representing "PERSONAL", "SERVICE"or "REMINDER"
- `title` **required**
- `message` **required**
- `subject` optional
- `to` optional (me), sometimes I send to someone else

### Outputs
- `ok` — `true` on 2xx
- `http_code` — numeric status

### Example

```yaml
name: PR Notify
on:
  pull_request:
    types: [opened, synchronize, reopened]

jobs:
  notify:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Send notification
        uses: ashgw/notify@main
        with:
          token: ${{ secrets.ASHGW_NOTIFY_TOKEN }}
          type: PR_OPENED
          title: ${{ github.event.pull_request.title }}
          message: "PR #${{ github.event.number }} by ${{ github.actor }} on ${{ github.repository }} (${{ github.head_ref }} -> ${{ github.base_ref }}) ${{ github.event.pull_request.html_url }}"
          # subject: "optional"
          # to: "optional@domain.tld"
````

Payload sent:

```json
{
  "type": "PR_OPENED",
  "title": "your title",
  "message": "your message",
  "subject": "optional",
  "to": "optional"
}
```

