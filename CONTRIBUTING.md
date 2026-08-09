# Contributing to BadexTechEvents

We use a lightweight Gitflow model.

## Branch Naming
- Features: `feature/short-description`
- Bug fixes: `fix/short-description`
- Hotfixes: `hotfix/short-description`

## Workflow
1. Branch off `dev`.
2. Make your changes locally.
3. Run `make lint` and `make test`. Ensure all tests pass.
4. Submit a Pull Request targeting the `dev` branch.
5. Once tested on `dev`, we will merge `dev` to `main` for production release.

## Local Development
1. Install requirements: `pip install -r requirements-dev.txt`
2. Configure AWS credentials locally (`aws configure`).
3. Set `EMAIL_PROVIDER=none` in your env when testing to avoid sending actual emails, or use `EMAIL_PROVIDER=smtp` with a test Gmail account.

## Commit Messages
We prefer Conventional Commits format:
- `feat: added admin login`
- `fix: resolved XSS issue in rendering`
- `docs: updated README`
- `chore: updated dependencies`
