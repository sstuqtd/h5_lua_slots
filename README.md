# h5_lua_slots

Use Lua to generate a browser-ready H5 slot mini game.

## Requirements

- Lua 5.4+ (`lua -v`)

## Generate H5 files

```bash
lua create_h5.lua [output_directory] [page_title]
```

Examples:

```bash
lua create_h5.lua
lua create_h5.lua demo_h5 "My Lua H5 Game"
```

This command generates:

- `index.html`
- `main.lua`
- `styles.css`

## Preview locally

```bash
python3 -m http.server 8080 --directory demo_h5
```

Then open `http://localhost:8080` in your browser.

## Deploy to GitHub Pages

This repository includes workflow:

- `.github/workflows/deploy-pages.yml`

Deployment behavior:

- Auto deploy on push to `main` when `demo_h5/**` changes
- Manual deploy with GitHub Actions `workflow_dispatch`

After deployment completes, the site URL follows:

```text
https://<github-username>.github.io/h5_lua_slots/
```
