from gettext import gettext as _
from typing import Any, Optional

from pulp_glue.common.context import (
    EntityDefinition,
    PluginRequirement,
    PulpContentContext,
    PulpDistributionContext,
    PulpRemoteContext,
    PulpRepositoryContext,
    PulpRepositoryVersionContext,
    registered_repository_contexts,
)


class PulpGemContentContext(PulpContentContext):
    # TODO adjust to the Gem content
    ENTITY = _("gem")
    ENTITIES = _("gems")
    HREF = "gem_gem_artifact_href"
    ID_PREFIX = "content_gem_artifact"
    NEEDS_PLUGINS = [PluginRequirement("gem", min="0.0.0")]


class PulpGemDistributionContext(PulpDistributionContext):
    ENTITY = _("gem distribution")
    ENTITIES = _("gem distributions")
    HREF = "gem_gem_distribution_href"
    ID_PREFIX = "distributions_gem_gem"
    NEEDS_PLUGINS = [PluginRequirement("gem", min="0.0.0")]

    def preprocess_body(self, body: EntityDefinition) -> EntityDefinition:
        body = super().preprocess_body(body)
        version = body.pop("version", None)
        if version is not None:
            repository_href = body.pop("repository")
            body["repository_version"] = f"{repository_href}versions/{version}/"
        return body


class PulpGemRemoteContext(PulpRemoteContext):
    ENTITY = _("gem remote")
    ENTITIES = _("gem remotes")
    HREF = "gem_gem_remote_href"
    ID_PREFIX = "remotes_gem_gem"
    NEEDS_PLUGINS = [PluginRequirement("gem", min="0.0.0")]


class PulpGemRepositoryVersionContext(PulpRepositoryVersionContext):
    HREF = "gem_gem_repository_version_href"
    ID_PREFIX = "repositories_gem_gem_versions"
    NEEDS_PLUGINS = [PluginRequirement("gem", min="0.0.0")]


class PulpGemRepositoryContext(PulpRepositoryContext):
    HREF = "gem_gem_repository_href"
    ID_PREFIX = "repositories_gem_gem"
    VERSION_CONTEXT = PulpGemRepositoryVersionContext
    NEEDS_PLUGINS = [PluginRequirement("gem", min="0.0.0")]


registered_repository_contexts["gem:gem"] = PulpGemRepositoryContext
