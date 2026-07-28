{{/*
app.kubernetes.io/name label. Defaults to "postgres", not .Chart.Name, to match
the manifests this chart replaces.
*/}}
{{- define "cnpg-database.name" -}}
{{- default "postgres" .Values.nameOverride | trunc 63 | trimSuffix "-" -}}
{{- end -}}

{{/*
Resource name stem. Defaults to the release name with no chart suffix: the
read-write Service is derived from the Cluster name (`<fullname>-rw`) and that
hostname is hardcoded by consumers, so a rename is a breaking change.
*/}}
{{- define "cnpg-database.fullname" -}}
{{- if .Values.fullnameOverride -}}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" -}}
{{- else -}}
{{- printf "%s" .Release.Name | trunc 63 | trimSuffix "-" -}}
{{- end -}}
{{- end -}}

{{- define "cnpg-database.labels" -}}
app.kubernetes.io/name: {{ include "cnpg-database.name" . }}
{{- end -}}

{{/*
Owning role: explicit owner, else the database name.
*/}}
{{- define "cnpg-database.owner" -}}
{{- default .Values.database .Values.owner -}}
{{- end -}}

{{/*
Secret holding the object store credentials.
*/}}
{{- define "cnpg-database.backupSecret" -}}
{{- default (printf "%s-backup" (include "cnpg-database.fullname" .)) .Values.backup.objectStore.credentials.secretName -}}
{{- end -}}

{{/*
Object store destination path.
*/}}
{{- define "cnpg-database.destinationPath" -}}
{{- if .Values.backup.objectStore.destinationPath -}}
{{- .Values.backup.objectStore.destinationPath -}}
{{- else -}}
{{- printf "%s/%s" (trimSuffix "/" .Values.backup.objectStore.bucketPrefix) (required "backup.objectStore.pathSuffix or backup.objectStore.destinationPath is required" .Values.backup.objectStore.pathSuffix) -}}
{{- end -}}
{{- end -}}
