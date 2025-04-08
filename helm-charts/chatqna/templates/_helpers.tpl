{{/*
Expand the name of the chart.
*/}}
{{- define "chatqna.name" -}}
{{- default .Chart.Name .Values.nameOverride | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Create a default fully qualified app name.
We truncate at 63 chars because some Kubernetes name fields are limited to this (by the DNS naming spec).
If release name contains chart name it will be used as a full name.
*/}}
{{- define "chatqna.fullname" -}}
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
{{- define "chatqna.chart" -}}
{{- printf "%s-%s" .Chart.Name .Chart.Version | replace "+" "_" | trunc 63 | trimSuffix "-" }}
{{- end }}

{{/*
Common labels
*/}}
{{- define "chatqna.labels" -}}
helm.sh/chart: {{ include "chatqna.chart" . }}
{{ include "chatqna.selectorLabels" . }}
{{- if .Chart.AppVersion }}
app.kubernetes.io/version: {{ .Chart.AppVersion | quote }}
{{- end }}
app.kubernetes.io/managed-by: {{ .Release.Service }}
{{- end }}

{{/*
Selector labels
*/}}
{{- define "chatqna.selectorLabels" -}}
app.kubernetes.io/name: {{ include "chatqna.name" . }}
app.kubernetes.io/instance: {{ .Release.Name }}
{{- end }}

{{/*
Create the name of the service account to use
*/}}
{{- define "chatqna.serviceAccountName" -}}
{{- if .Values.global.sharedSAName }}
{{- .Values.global.sharedSAName }}
{{- else if .Values.serviceAccount.create }}
{{- default (include "chatqna.fullname" .) .Values.serviceAccount.name }}
{{- else }}
{{- default "default" .Values.serviceAccount.name }}
{{- end }}
{{- end }}

{{/*
Determine if global LLM server should be used
*/}}
{{- define "chatqna.useGlobalLLMServer" -}}
{{- if and .Values.global .Values.global.LLM_SERVER_HOST_IP (ne .Values.global.LLM_SERVER_HOST_IP "insert-your-llm-server-host-ip-here") -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}

{{/*
Determine if we should set the OpenAI API key environment variable
*/}}
{{- define "chatqna.shouldSetOpenAIKey" -}}
{{- if and .Values.global .Values.global.OPENAI_API_KEY (ne .Values.global.OPENAI_API_KEY "insert-your-openai-api-key-here") -}}
{{- true -}}
{{- else -}}
{{- false -}}
{{- end -}}
{{- end -}}

{{/*
Get proper OpenAI API key value (only used when shouldSetOpenAIKey is true)
*/}}
{{- define "chatqna.openaiAPIKey" -}}
{{- if and .Values.global .Values.global.OPENAI_API_KEY -}}
{{- .Values.global.OPENAI_API_KEY -}}
{{- end -}}
{{- end -}}
