#!/bin/bash
# set up "automatic" 'pre-commit' hooks using git `templatedir`
# this will install the regular ("pre-commit") and "commit-msg" hooks
# also see https://pre-commit.com/#pre-commit-init-templatedir

type -p pre-commit > /dev/null || exit 0
git config --global init.templateDir > /dev/null && exit 0

git config --global init.templateDir ~/.config/git/templates
pre-commit init-templatedir ~/.config/git/templates/
pre-commit init-templatedir --hook-type commit-msg ~/.config/git/templates/
