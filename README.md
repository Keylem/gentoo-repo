# gentoo-repo

Personal custom Portage repository.

## Overlay identity

- Repository name: `keylem`
- Masters: `gentoo`

## Included package

- `app-misc/kait2en` (live ebuild)

The `app-misc/kait2en` ebuild pulls `Keylem/KaiT2en-Gentoo` from branch
`copilot/modify-kai2ten-for-gentoo`, installs it into `/opt/kait2en`, and
provides the helper command:

```bash
kait2en-gentoo-install
```

Use that command as root after emerging the package to run the project Gentoo
installer steps.
