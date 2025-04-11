# Welcome to [Slidev](https://github.com/slidevjs/slidev)!

## Local-preview

1. Use `local-preview.sh`

```bash
./scripts/local-preview.sh
```

or run steps manually. To start the slide show locally from scratch:

- `npm install`
- `npm run dev`

2. The browser should open automatically. If not, use `o` shortcut or open
   slides at: <http://localhost:3030>.

3. Edit the [slides.md](./slides.md) to render other slides/training modules.
   Use `Ctrl+Shift+R` to hard reload the page bypassing the cached resources.

> Note: To start the slide show with remote access on port 8088:
> 
> - `npm run dev -- -p 8088 --remote`

Learn more about Slidev at the [documentation](https://sli.dev/).

## Automated workflow

Script is integrated into `scripts/render-slides.sh`.
