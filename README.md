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
- `unity_api.lua` (Unity-style helper API for Lua)
- `main.lua`
- `styles.css`

`unity_api.lua` exposes Unity-like helpers:

- `Unity.Debug.Log / LogWarning / LogError / Assert`
- `Unity.Random.Range`
- `Unity.Mathf.Clamp / FloorToInt`
- `Unity.Time.deltaTime / time`
- `Unity.MonoBehaviour:New()` and `Unity.Application.Run(...)`

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

First-time setup (required if Pages is disabled):

1. Open GitHub repository **Settings → Pages**
2. In **Build and deployment**, choose **Source: GitHub Actions**
3. Re-run the workflow from **Actions** tab

Optional auto-enable setup:

- Create repository secret `PAGES_DEPLOY_TOKEN`
- Use a token with Pages write/admin capability
- Then workflow can try enabling Pages automatically

After deployment completes, the site URL follows:

```text
https://<github-username>.github.io/h5_lua_slots/
```
