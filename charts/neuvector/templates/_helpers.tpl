{{/*
Expand the name of the chart.
*/}}
{{- define "neuvector.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
*/}}
{{- define "neuvector.fullname" -}}
{{- if .Values.fullnameOverride }}
{{- .Values.fullnameOverride | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- $name := default .Chart.Name .Values.nameOverride }}
{{- if contains $name .Release.Name }}
{{- .Release.Name | trunc 63 | trimSuffix "-" }}
{{- else }}
{{- printf "%s-%s" .Release.Name $name | trunc 63 | trimSuffix "-" }}
{{- end }}
{{- end }}
{{- end }}

{{/*
Create chart name and version as used by the chart label.
*/}}
{{- define "neuvector.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "neuvector.labels" -}}
helm.sh/chart: {{ include "neuvector.chart" . }}
{{ include "neuvector.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "neuvector.selectorLabels" -}}
app.kubernetes.io/name: {{ include "neuvector.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Get Rancher URL - helper for templates that need the Rancher URL
Priority: neuvector-core.global.cattle.url > global.rancher.url > empty
*/}}
{{- define "neuvector.rancherUrl" -}}
{{- if .Values.neuvector-core.global.cattle.url }}
{{- .Values.neuvector-core.global.cattle.url }}
{{- else if .Values.global.rancher.url }}
{{- .Values.global.rancher.url }}
{{- else }}
{{- "" }}
{{- end }}
{{- end }}

{{/*
Get runtime path - helper for templates that need the runtime path
Priority: neuvector-core.runtimePath > global.runtime.path > default
*/}}
{{- define "neuvector.runtimePath" -}}
{{- if .Values.neuvector-core.runtimePath }}
{{- .Values.neuvector-core.runtimePath }}
{{- else if .Values.global.runtime.path }}
{{- .Values.global.runtime.path }}
{{- else }}
{{- "/run/k3s/containerd/containerd.sock" }}
{{- end }}
{{- end }}

