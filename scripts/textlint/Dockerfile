# Image bundling textlint and the rules/plugins used by this repository, so that
# text linting can run without a local Node.js/Yarn installation.
# The base image is updated by Renovate's native Dockerfile manager; the ARG
# versions below are updated by the custom manager configured in renovate.json.
FROM node:24-alpine

# renovate: datasource=npm depName=textlint
ARG TEXTLINT_VERSION=15.7.1
# renovate: datasource=npm depName=textlint-filter-rule-comments
ARG TEXTLINT_FILTER_RULE_COMMENTS_VERSION=1.3.0
# renovate: datasource=npm depName=textlint-rule-common-misspellings
ARG TEXTLINT_RULE_COMMON_MISSPELLINGS_VERSION=1.0.1
# renovate: datasource=npm depName=textlint-rule-no-dead-link
ARG TEXTLINT_RULE_NO_DEAD_LINK_VERSION=6.2.3
# renovate: datasource=npm depName=textlint-rule-no-todo
ARG TEXTLINT_RULE_NO_TODO_VERSION=2.0.1
# renovate: datasource=npm depName=textlint-rule-terminology
ARG TEXTLINT_RULE_TERMINOLOGY_VERSION=5.2.16

RUN npm install -g --ignore-scripts \
  "textlint@${TEXTLINT_VERSION}" \
  "textlint-filter-rule-comments@${TEXTLINT_FILTER_RULE_COMMENTS_VERSION}" \
  "textlint-rule-common-misspellings@${TEXTLINT_RULE_COMMON_MISSPELLINGS_VERSION}" \
  "textlint-rule-no-dead-link@${TEXTLINT_RULE_NO_DEAD_LINK_VERSION}" \
  "textlint-rule-no-todo@${TEXTLINT_RULE_NO_TODO_VERSION}" \
  "textlint-rule-terminology@${TEXTLINT_RULE_TERMINOLOGY_VERSION}"

WORKDIR /data
ENTRYPOINT ["textlint"]
