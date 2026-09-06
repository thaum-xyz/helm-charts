# cnpg-database

![Version: 0.10.2](https://img.shields.io/badge/Version-0.10.2-informational?style=flat-square) ![Type: application](https://img.shields.io/badge/Type-application-informational?style=flat-square)

CloudNativePG cluster with barman-cloud object store, scheduled backups, Doppler-backed credentials and backup alerting

**Homepage:** <https://github.com/thaum-xyz/helm-charts>

## Source Code

* <https://github.com/thaum-xyz/helm-charts/tree/main/charts/cnpg-database>

## Values

| Key | Type | Default | Description |
|-----|------|---------|-------------|
| backup.backupOwnerReference | string | `"self"` |  |
| backup.enabled | bool | `true` |  |
| backup.objectStore.bucketPrefix | string | `"s3://cnpg/postgres"` |  |
| backup.objectStore.credentials.accessKeyKey | string | `"S3_ACCESS_KEY"` |  |
| backup.objectStore.credentials.secretKeyKey | string | `"S3_SECRET_KEY"` |  |
| backup.objectStore.credentials.secretName | string | `""` | Empty means <fullname>-backup. |
| backup.objectStore.destinationPath | string | `""` | Escape hatch; wins over bucketPrefix/pathSuffix. |
| backup.objectStore.endpointURL | string | `"http://versitygw.cnpg-system.svc.cluster.local:7070"` | The in-cluster gateway. Backblaze was the previous target; every cluster moved off it, so a new one defaulting there would have been a silent regression. |
| backup.objectStore.name | string | `"versity"` | NOT derived from the release name: several namespaces host more than one cluster and each needs its own store. |
| backup.objectStore.pathSuffix | string | `""` | Required. Note this is not always the namespace name. |
| backup.objectStore.retentionPolicy | string | `"30d"` | Varies per database (3d to 30d in practice); no safe default beyond this. |
| backup.objectStore.wal.compression | string | `"gzip"` |  |
| backup.pluginName | string | `"barman-cloud.cloudnative-pg.io"` |  |
| backup.schedule | string | `"0 17 23 * * *"` |  |
| backup.suspend | bool | `false` |  |
| cluster.affinity.enablePodAntiAffinity | bool | `true` |  |
| cluster.affinity.podAntiAffinityType | string | `"required"` |  |
| cluster.affinity.topologyKey | string | `"kubernetes.io/hostname"` |  |
| cluster.annotations | object | `{}` | Extra annotations on the Cluster. |
| cluster.bootstrap.enabled | bool | `true` | false omits spec.bootstrap entirely. Needed for clusters that are already initialised and have no bootstrap stanza in their live spec; adding one can be rejected by the validating webhook. |
| cluster.bootstrap.postInitApplicationSQL | list | `[]` |  |
| cluster.bootstrap.postInitSQL | list | `[]` |  |
| cluster.imageName | string | `"ghcr.io/cloudnative-pg/postgresql:17.11-standard-bookworm"` | The chart owns the version, so clusters do not have to pin one and drift apart. Left unset, CloudNativePG defaults it at creation and freezes that value into the spec forever, which is how one fleet ended up spanning 15.2 to 18.1 with nobody choosing any of it. 17 on bookworm matches the VectorChord image immich needs, so photos is not a major-version outlier. Overriding this is for clusters that cannot follow: changing the major triggers an offline pg_upgrade, and PostgreSQL has no downgrade path at all. |
| cluster.instances | int | `2` |  |
| cluster.monitoring.enablePodMonitor | bool | `false` | Deprecated upstream; the chart renders the PodMonitor itself. See templates/podmonitor.yaml. |
| cluster.postgresql | object | `{"parameters":{"archive_timeout":"900s","checkpoint_timeout":"900s","max_slot_wal_keep_size":"512MB","wal_compression":"lz4","wal_keep_size":"128MB"}}` | Passthrough for spec.postgresql (parameters, shared_preload_libraries...). The parameters below bound WAL growth; a per-database values file can override any single key, because Helm deep-merges maps. |
| cluster.primaryUpdateMethod | string | `""` | Empty means omit spec.primaryUpdateMethod. |
| cluster.resources | object | `{}` | Deliberately empty. Helm deep-merges maps, so a default limits block could not be removed by omission in a per-instance values file -- it would silently impose limits on the clusters that intentionally set requests only. |
| cluster.storage.size | string | `"2Gi"` |  |
| cluster.storage.storageClass | string | `"lvm-thin"` |  |
| database | string | `""` | Application database name. Required unless cluster.bootstrap.enabled=false. |
| externalSecrets.admin.remoteKey | string | `""` | Doppler key for the superuser password. Required. |
| externalSecrets.admin.username | string | `"postgres"` |  |
| externalSecrets.annotations | object | `{}` | Extra annotations on the ExternalSecret objects themselves. Empty by default, and deliberately so: annotations here do NOT reach the generated Secret. External Secrets copies spec.target.template metadata onto the Secret, and falls back to copying the ExternalSecret's own metadata only when no template is set at all. Use secretLabels below for anything the operator has to see. |
| externalSecrets.backup.accessKeyRemoteKey | string | `"POSTGRES_S3_ACCESS_KEY"` |  |
| externalSecrets.backup.secretKeyRemoteKey | string | `"POSTGRES_S3_SECRET_KEY"` |  |
| externalSecrets.enabled | bool | `true` |  |
| externalSecrets.refreshInterval | string | `"1h"` |  |
| externalSecrets.secret.metadata | object | `{"labels":{"cnpg.io/reload":"true"}}` | Metadata for the generated Secrets, passed through verbatim as spec.target.template.metadata, so both `labels` and `annotations` work and the shape matches the External Secrets API rather than inventing one.  cnpg.io/reload is a *label*, not an annotation, and belongs on the Secret, not on the ExternalSecret. CloudNativePG documents it under predefined labels: "Available on ConfigMap and Secret resources. When set to true, a change in the resource is automatically reloaded by the operator." This is the only placement that makes a rotated password actually get picked up.  Set to `null` -- not `{}` -- to render no template metadata at all: Helm deep-merges maps, so `{}` leaves the default below in place. |
| externalSecrets.secretStoreRef.kind | string | `"ClusterSecretStore"` |  |
| externalSecrets.secretStoreRef.name | string | `"doppler-auth-api"` |  |
| externalSecrets.user.remoteKey | string | `""` | Doppler key for the application password. Required. |
| externalSecrets.user.username | string | `""` | Empty falls back to .Values.owner, then .Values.database. |
| fullnameOverride | string | `""` | Resource name stem. Defaults to .Release.Name. IMPORTANT: this must render to the same name the cluster already uses, because CloudNativePG derives the read-write Service from it (`<fullname>-rw`) and that hostname is hardcoded by every consumer. Do not let it become "<release>-<chart>". |
| nameOverride | string | `""` | Value of the app.kubernetes.io/name label. Defaults to "postgres" rather than the chart name, because that is what the existing manifests use. |
| owner | string | `""` | Owning role. Defaults to .Values.database. Also used as the username in the user ExternalSecret, so it is needed even when bootstrap is disabled. |
| podMonitor | object | `{"enabled":true}` | Chart-managed PodMonitors for the cluster and, when enabled, the pooler. Replaces the operator's own, which CloudNativePG has deprecated. |
| pooler.enabled | bool | `false` |  |
| pooler.instances | int | `2` |  |
| pooler.monitoring.enablePodMonitor | bool | `false` | Deprecated upstream, as for the cluster. |
| pooler.name | string | `"pooler"` | Live name is "pooler", not "<fullname>-pooler". |
| pooler.pgbouncer.parameters.default_pool_size | string | `"10"` |  |
| pooler.pgbouncer.parameters.max_client_conn | string | `"1000"` |  |
| pooler.pgbouncer.poolMode | string | `"session"` |  |
| pooler.podLabel | string | `"pooler"` |  |
| pooler.resources | object | `{}` | Resource requests and limits for the operator-managed pgbouncer container. |
| pooler.type | string | `"rw"` |  |
| prometheusRule.enabled | bool | `true` | Backup alerting. Deliberately built on the barman plugin's own metrics (barman_cloud_cloudnative_pg_io_*) and NOT on cnpg_collector_*: the built-in collector metrics read 0 for plugin-method backups, so an alert on them would fire constantly while telling you nothing. |
| prometheusRule.maxBackendsWaiting | int | `300` | Warn when more than this many backends are blocked on locks. |
| prometheusRule.maxBackupAgeSeconds | int | `172800` | Warn when the newest backup is older than this many seconds (default 2d). |
| prometheusRule.maxDeadlocksPerHour | int | `10` | Warn when this many deadlock conflicts are recorded within an hour. Measured with increase(), not read off the counter directly: the raw metric is a lifetime total, so a threshold against it fires forever once crossed. |
| prometheusRule.maxReplicationLagSeconds | int | `300` | Warn when a standby lags the primary by more than this many seconds. |
| prometheusRule.maxTransactionSeconds | int | `300` | Warn when a single transaction has been open longer than this many seconds. Raise it per release for a database with a legitimate long-running batch job; an open transaction holds back vacuum, so do not raise it far. |
| prometheusRule.maxWalSegmentsReady | int | `10` | Warn when this many WAL segments sit unarchived in archive_status/ready and do not drain. Steady state is 0; max_wal_size allows 64 segments before pg_wal stops growing on its own, so this fires well ahead of a full volume. |
| prometheusRule.maxXidAge | int | `150000000` | Warn when transactions since the frozen XID exceed this. |
| retain | bool | `true` | Adds helm.sh/resource-policy: keep to the Cluster and ObjectStore so no Helm action (including an install-remediation uninstall) can delete the Cluster and, through its ownerReferences, its PVCs. |

----------------------------------------------
Autogenerated from chart metadata using [helm-docs v1.14.2](https://github.com/norwoodj/helm-docs/releases/v1.14.2)
