# Installationsanleitung zur Bereitstellung der AWS-Infrastruktur mit Terraform


## 1. Voraussetzungen
Vor der Ausführung der Terraform-Skripte müssen folgende Voraussetzungen erfüllt sein:

- Ein aktives AWS-Konto
- Installierte und konfigurierte AWS Command Line Interface (AWS CLI)
- Installiertes Terraform: https://developer.hashicorp.com/terraform/install
- Ein AWS IAM-Benutzer mit ausreichenden Berechtigungen für die verwendeten AWS-Dienste
- Zugriff auf ein Terminal oder eine Shell
- Zugriff auf das Projektverzeichnis mit den Terraform-Dateien

Empfohlene Versionen:

- Terraform: Version 1.x
- AWS CLI: Version 2.x

Die Authentifizierung gegenüber AWS erfolgt über die lokal konfigurierte AWS CLI. Hierfür muss vorab folgender Befehl ausgeführt werden:

```bash
aws configure
```

Dabei werden die AWS Access Key ID, der AWS Secret Access Key, die Standardregion sowie das Ausgabeformat hinterlegt. Für dieses Projekt wurde als Region eu-central-1 verwendet.

## 2. Projektstruktur

Die Projektstruktur ist wie folgt aufgebaut:

```text
aws-cloud-infrastructure/
│
├── provider.tf
├── variables.tf
├── main.tf
├── .terraform.lock.hcl
├── .gitignore
├── INSTALLATION.md
│
└── website/
    └── index.html
```

## 3. Vorbereitung

Zunächst in das Projektverzeichnis wechseln:

```bash
cd aws-cloud-infrastructure
```

Anschließend Terraform initialisieren:

```bash
terraform init
```

## 4. Konfiguration prüfen

Die Terraform-Konfiguration formatieren:

```bash
terraform fmt
```

Die Konfiguration validieren:

```bash
terraform validate
```

Anschließend den Ausführungsplan anzeigen:

```bash
terraform plan
```

## 5. Infrastruktur bereitstellen

Die Infrastruktur wird mit folgendem Befehl erstellt:

```bash
terraform apply
```

Die Ausführung muss anschließend mit

```text
yes
```

bestätigt werden.

Nach erfolgreicher Ausführung werden die definierten AWS-Ressourcen erstellt. Dazu gehören unter anderem der S3-Bucket, CloudFront, die Virtual Private Cloud (VPC), Subnetze, Security Groups, der Application Load Balancer (ALB), EC2-Instanzen, die Auto Scaling Group (ASG), IAM-Rollen sowie der AWS Secrets Manager.

## 6. Überprüfung der Bereitstellung

Nach der Bereitstellung kann die Infrastruktur in der AWS-Managementkonsole überprüft werden. Zusätzlich kann Terraform den aktuellen Zustand der verwalteten Ressourcen anzeigen:

```bash
terraform state list
```

Die bereitgestellte Webseite kann anschließend über die von CloudFront erzeugte Domain aufgerufen werden.

## 7. Infrastruktur entfernen

Nach Abschluss des Projekts kann die gesamte Infrastruktur wieder entfernt werden:

```bash
terraform destroy
```

Auch dieser Vorgang muss mit

```text
yes
```

bestätigt werden. 

Terraform löscht anschließend alle zuvor bereitgestellten Ressourcen, soweit sie in der Konfiguration enthalten und im Terraform-State verwaltet werden.

## 8. Hinweise

Sensible Dateien und automatisch erzeugte Terraform-Arbeitsdateien dürfen nicht in die Versionsverwaltung aufgenommen werden. Dazu gehören insbesondere:

```text
.terraform/
terraform.tfstate
terraform.tfstate.backup
.terraform.tfstate.lock.info
*.tfvars
```

Diese Dateien enthalten lokale Zustandsinformationen oder potenziell sensible Konfigurationswerte und sind daher in der `.gitignore` ausgeschlossen. Die Datei `.terraform.lock.hcl` kann hingegen versioniert werden, da sie die verwendete Provider-Version festhält und damit zur Reproduzierbarkeit beiträgt.
