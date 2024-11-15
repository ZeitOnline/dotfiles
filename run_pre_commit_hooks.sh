#!/bin/bash
# set up "automatic" 'pre-commit' hooks using git `templatedir`
# this will install the regular ("pre-commit") and "commit-msg" hooks
# also see https://pre-commit.com/#pre-commit-init-templatedir

if [ -z "( git config --global init.templateDir )" ]; then
    git config --global init.templateDir ~/.config/git/templates
fi

pre-commit init-templatedir ~/.config/git/templates/
pre-commit init-templatedir --hook-type commit-msg ~/.config/git/templates/
