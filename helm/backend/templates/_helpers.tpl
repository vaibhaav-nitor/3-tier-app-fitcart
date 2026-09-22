{{/*
Name of the ServiceAccount the backend pods run as. Falls back to a fixed
name derived from the chart's own app label — not the release name — so it
stays stable across releases the way the Service names already do.
*/}}
{{- define "backend.serviceAccountName" -}}
{{- if .Values.serviceAccount.create -}}
{{- .Values.serviceAccount.name | default "backend" -}}
{{- else -}}
{{- .Values.serviceAccount.name | default "default" -}}
{{- end -}}
{{- end -}}
