{{/*
Expand the name of the chart.
*/}}
{{- define "codegen.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "codegen.fullname" -}}
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
{{- define "codegen.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "codegen.labels" -}}
helm.sh/chart: {{ include "codegen.chart" . }}
{{ include "codegen.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "codegen.selectorLabels" -}}
app.kubernetes.io/name: {{ include "codegen.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "codegen.serviceAccountName" -}}
{{- if .Values.global.sharedSAName }}
{{- .Values.global.sharedSAName }}
{{- else if .Values.serviceAccount.create }}
{{- default (include "codegen.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Determine if global LLM server is being used
*/}}
{{- define "codegen.useGlobalLLM" -}}
{{- if .Values.global.LLM_SERVER_HOST_IP }}
{{- true }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
Check if OpenAI API Key is set and not default
*/}}
{{- define "codegen.isOpenAIKeySet" -}}
{{- if and .Values.global.OPENAI_API_KEY (ne .Values.global.OPENAI_API_KEY "insert-your-openai-key-here") (ne .Values.global.OPENAI_API_KEY "none") }}
{{- true }}
{{- else }}
{{- false }}
{{- end }}
{{- end }}

{{/*
Get OpenAI API Key
*/}}
{{- define "codegen.getOpenAIKey" -}}
{{- if and .Values.global.OPENAI_API_KEY (ne .Values.global.OPENAI_API_KEY "insert-your-openai-key-here") (ne .Values.global.OPENAI_API_KEY "none") }}
{{- .Values.global.OPENAI_API_KEY }}
{{- else }}
{{- "none" }}
{{- end }}
{{- end }}
