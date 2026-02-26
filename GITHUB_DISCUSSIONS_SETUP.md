# GitHub Discussions Setup

GitHub Discussions must be enabled and categories configured manually.

## Enable Discussions

GitHub → cubeos-app/releases repo → Settings → Features → Discussions → Enable

(Use releases repo as the primary discussion hub, link others there)

## Categories to create

| Category | Type | Description |
|----------|------|-------------|
| Announcements | Announcement | Release announcements (maintainer-only posts) |
| General | Open-ended discussion | General CubeOS chat |
| Q&A | Question / Answer | Get help, ask questions |
| Ideas | Open-ended discussion | Feature ideas and feedback |
| Show and Tell | Open-ended discussion | Share your CubeOS setup |

## After setup

Update `config.yml` discussion link in `.github/ISSUE_TEMPLATE/config.yml` to point to the correct category URL.
