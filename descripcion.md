# Descripcion del Workflow de Deploy

Este documento describe el workflow [.github/workflows/deploy-aws-module-1.yml](.github/workflows/deploy-aws-module-1.yml), cuyo objetivo es desplegar la base de infraestructura en AWS y F5 Distributed Cloud, y despues publicar el contenido de `module_1` sobre el mK8s del sitio.

## Nombre del workflow

`Deploy AWS Prerequisites And Module 1`

## Como se ejecuta

El workflow se ejecuta manualmente mediante `workflow_dispatch`.

No recibe parametros de entrada en la invocacion. Toda la configuracion se toma desde variables y secretos del repositorio.

## Que hace en terminos generales

El deploy se divide en dos jobs secuenciales:

1. `prerequisites`
   Crea o reutiliza la base necesaria para el entorno: namespace XC, VPC, subnet, App Stack site, mK8s y VM kiosk.

2. `module_1`
   Espera a que el sitio y el API de mK8s esten listos, genera un kubeconfig temporal y luego aplica el contenido de `module_1`.

## Variables y secretos relevantes

Variables de repositorio usadas por el workflow:

- `AWS_REGION`
- `PROJECT_PREFIX`
- `VPC_CIDR_MK8S`
- `XC_NAMESPACE`
- `XC_SERVICE_CREDENTIAL_ROLE`
- `EXISTING_MK8S_CLUSTER_NAME`
- `PASSWORD_VM_WINDOWS`

Secrets usados por el workflow:

- `TF_API_TOKEN`
- `TF_CLOUD_ORGANIZATION`
- `XC_API_URL`
- `XC_API_P12_FILE`
- `XC_P12_PASSWORD`
- `AWS_ACCESS_KEY`
- `AWS_SECRET_KEY`

## Flujo General

```mermaid
flowchart TD
    A[Inicio manual del workflow] --> B[Job prerequisites]
    B --> C[Recolectar outputs: app_stack_name, mk8s_cluster_name, xc_namespace, workspace_prefix]
    C --> D[Job module_1]
    D --> E[Fin del deploy]
```

## Topologia de la arquitectura desplegada

La referencia original de `f5devcentral/xcawsedgedemoguide` presenta una arquitectura completa de BuyTime distribuida entre Retail Branch, Customer Edge y Regional Edge. Este workflow implementa solo una porcion de ese escenario: la parte de **Retail Branch sobre App Stack en AWS**, junto con la integracion hacia un servicio externo de recomendaciones.

Dicho de otra forma:

- la guia original muestra un escenario multisitio y multicloud mas amplio
- este workflow automatiza el tramo **Pre-Requisites + Module 1**
- no despliega CE, vK8s, sincronizacion de inventario ni Regional Edge
- si deja operativa la sucursal o branch con App Stack, mK8s, kiosk VM y los HTTP load balancers internos de `kiosk` y `recommendations`

### Alcance arquitectonico implementado por este workflow

```mermaid
flowchart LR
    subgraph FULL[Escenario de referencia BuyTime]
        RB[Retail Branch]
        CE[Customer Edge]
        RE[Regional Edge]
    end

    RB:::implemented
    CE:::notimplemented
    RE:::notimplemented

    classDef implemented fill:#d9f2d9,stroke:#2d6a4f,stroke-width:2px,color:#111;
    classDef notimplemented fill:#f3f4f6,stroke:#9ca3af,stroke-width:1px,color:#444;
```

### Resumen de componentes realmente desplegados

El resultado final del workflow es esta arquitectura funcional:

- una VPC en AWS para el branch
- una subnet principal donde viven el App Stack site y la VM kiosk
- un `aws_vpc_site` de F5 XC sobre esa VPC
- un mK8s administrado por XC, creado o reutilizado
- una VM Windows kiosk con acceso RDP por IP publica
- un namespace de aplicacion en mK8s
- tres workloads Kubernetes para la experiencia de retail kiosk
- un HTTP load balancer interno para el frontend kiosk
- un HTTP load balancer interno para el servicio de recomendaciones
- un origin pool Kubernetes para el kiosco
- un origin pool por DNS publico para recomendaciones externas

## Vista de escenario tipo guia, ajustada al workflow real

Esta vista intenta parecerse mas a la narrativa del repo de referencia, pero mostrando solo lo que este workflow materializa.

```mermaid
flowchart LR
    Shopper[Operador o usuario en sucursal] --> KioskVM[Windows kiosk VM]

    subgraph AWS[AWS Retail Branch VPC]
        subgraph BranchSubnet[Subnet del branch]
            AppStackNode[App Stack site node]
            KioskVM
        end
    end

    subgraph XC[F5 Distributed Cloud]
        SystemNS[system namespace]
        AppNS[Application namespace XC_NAMESPACE]
        MK8S[mK8s buytime.internal]
        KioskLB[HTTP LB kiosk.namespace.buytime.internal]
        RecLB[HTTP LB recommendations.namespace.buytime.internal]
        KioskPool[Origin pool -> kiosk-service.namespace]
        RecPool[Origin pool -> recommendations origin DNS]
    end

    subgraph MKSCOPE[mK8s workloads en el branch]
        MySQL[(MySQL pod)]
        WordPress[WordPress pod]
        KioskProxy[Kiosk reverse proxy pod]
    end

    ExternalRec[Servicio externo de recomendaciones]

    SystemNS --> MK8S
    AppStackNode --> MK8S
    AppNS --> KioskLB
    AppNS --> RecLB
    KioskLB --> KioskPool
    RecLB --> RecPool
    KioskPool --> KioskProxy
    KioskProxy --> WordPress
    WordPress --> MySQL
    RecPool --> ExternalRec
    KioskVM --> KioskLB
    KioskVM --> RecLB
```

## Planos de la arquitectura

Para que la topologia sea mas clara, conviene separarla en cuatro planos: automatizacion, control, infraestructura y datos o trafico.

### 1. Plano de automatizacion

Este plano describe quien despliega y donde se guarda el estado.

- GitHub Actions coordina el orden de ejecucion
- Terraform Cloud guarda el estado remoto en workspaces separados
- el workflow se comunica con AWS y F5 XC usando credenciales del repositorio
- el job `prerequisites` publica outputs consumidos por `module_1`

```mermaid
flowchart LR
    User[Operador] --> GHA[GitHub Actions workflow_dispatch]
    GHA --> P[Job prerequisites]
    P --> TFC1[Terraform Cloud prerequisites workspace]
    P --> AWS[AWS API]
    P --> XC[F5 XC API]
    P --> OUT[Outputs del job]
    OUT --> M1[Job module_1]
    M1 --> TFC2[Terraform Cloud module-1 workspace]
    M1 --> XC
    M1 --> AWS
```

### 2. Plano de control

Este plano muestra como F5 XC controla la infraestructura del branch.

- el namespace `system` de XC contiene el `aws_vpc_site` y el mK8s
- el namespace de aplicacion contiene los objetos de exposicion de `module_1`
- el sitio App Stack se enlaza al mK8s asociado
- el workflow genera una credencial temporal para obtener kubeconfig del sitio

```mermaid
flowchart TD
    XCAPI[F5 XC control plane API]
    XCAPI --> SYS[system namespace]
    XCAPI --> APPNS[application namespace XC_NAMESPACE]

    SYS --> Site[volterra_aws_vpc_site]
    SYS --> MK8S[volterra_k8s_cluster o cluster reutilizado]
    Site --> MK8S

    APPNS --> KLB[volterra_http_loadbalancer kiosk]
    APPNS --> RLB[volterra_http_loadbalancer recommendations]
    APPNS --> KOP[volterra_origin_pool kiosk]
    APPNS --> ROP[volterra_origin_pool recommendations]

    KLB --> KOP
    RLB --> ROP
```

### 3. Plano de infraestructura en AWS

Este workflow materializa un branch sencillo en una sola VPC y una sola subnet.

Recursos principales:

- `aws_vpc`
- `aws_subnet`
- `aws_instance.kiosk`
- `aws_security_group.kiosk_sg`
- `aws_key_pair.kiosk_key_pair`
- nodo del App Stack site desplegado por XC dentro de la misma subnet

Características importantes:

- la VM kiosk tiene IP publica para RDP
- el App Stack site usa una sola interfaz y queda sin `internet VIP`
- tanto la VM como el nodo del sitio comparten la red privada del branch
- el workflow consulta la interfaz de red del App Stack para descubrir su IP privada

```mermaid
flowchart TB
    subgraph VPC[AWS VPC CIDR VPC_CIDR_MK8S]
        subgraph Subnet[Subnet principal del branch]
            AppNode[App Stack site node]
            VM[Windows kiosk VM]
        end
        SG[Security Group kiosk_sg]
        KP[EC2 key pair]
    end

    SG --> VM
    KP --> VM
    VM -. RDP 3389 publico .-> Internet[Internet para administracion]
    VM -->|trafico privado| AppNode
```

### 4. Plano de workloads en mK8s

Dentro del mK8s, el workflow implementa una aplicacion tipo branch kiosk basada en tres componentes.

```mermaid
flowchart LR
    subgraph NS[Namespace XC_NAMESPACE]
        MDP[mysql-deployment]
        MSVC[mysql-service:3306]
        WDP[wordpress-deployment]
        WSVC[wordpress-service:8080]
        KDP[kiosk-deployment]
        KSVC[kiosk-service:8080]
    end

    MDP --> MSVC
    WDP --> WSVC
    KDP --> KSVC
    WDP -->|WORDPRESS_DB_HOST=mysql-service| MSVC
    KDP -->|reverse proxy| WSVC
```

#### Funcion de cada componente

- `mysql-deployment`: base de datos para WordPress
- `wordpress-deployment`: aplicacion principal de BuyTime basada en WooCommerce
- `kiosk-deployment`: reverse proxy frontal que expone la experiencia kiosk
- `mysql-service`: servicio ClusterIP para la base de datos
- `wordpress-service`: servicio ClusterIP para la app WordPress
- `kiosk-service`: servicio ClusterIP consumido por el HTTP LB interno de XC

## Topologia de exposicion de servicios

La exposicion de la aplicacion se hace con dos HTTP load balancers internos en XC, ambos anunciados en el App Stack site.

### Dominio 1: kiosk

- dominio: `kiosk.<namespace>.buytime.internal`
- tipo: `volterra_http_loadbalancer`
- origen: `kiosk-service.<namespace>` sobre el sitio App Stack
- puerto de origen: `8080`

### Dominio 2: recommendations

- dominio: `recommendations.<namespace>.buytime.internal`
- tipo: `volterra_http_loadbalancer`
- origen: DNS publico externo configurado en el modulo
- puerto de origen: variable `recommendations_origin_port`
- TLS habilitado hacia el origen externo

### Vista detallada de exposicion

```mermaid
flowchart LR
    VM[Windows kiosk VM]

    subgraph XCAPP[XC Application Namespace]
        KLB[HTTP LB kiosk]
        KOP[Origin Pool kiosk]
        RLB[HTTP LB recommendations]
        ROP[Origin Pool recommendations]
    end

    subgraph MKSVC[mK8s services]
        KSVC[kiosk-service.namespace:8080]
        WSVC[wordpress-service.namespace:8080]
        MSVC[mysql-service.namespace:3306]
    end

    EXTREC[External recommendations service]

    VM -->|Host kiosk.namespace.buytime.internal| KLB
    VM -->|Host recommendations.namespace.buytime.internal| RLB
    KLB --> KOP
    KOP --> KSVC
    KSVC --> WSVC
    WSVC --> MSVC
    RLB --> ROP
    ROP --> EXTREC
```

## Topologia DNS y resolucion de nombres

Este punto es importante porque es distinto de lo que a veces se asume al ver un load balancer en XC.

Lo que implementa el workflow es esto:

- crea dominios lógicos en los HTTP load balancers
- **no** crea DNS administrado por XC para esos dominios
- usa `dns_volterra_managed = false`
- resuelve el acceso desde la VM kiosk escribiendo entradas en `hosts`

Consecuencia directa:

- los nombres existen como hostnames configurados en el LB
- la resolucion local desde la VM depende del archivo `hosts`
- el trafico funciona por nombre dentro de la VM porque el `user_data` mapea ambos nombres a la IP privada del App Stack site

### Vista de resolucion local

```mermaid
flowchart LR
    Hosts[Archivo hosts en Windows] --> Name1[kiosk.namespace.buytime.internal]
    Hosts --> Name2[recommendations.namespace.buytime.internal]
    Name1 --> AppIP[IP privada del App Stack site]
    Name2 --> AppIP
    AppIP --> XCInside[VIP interno anunciado en el sitio]
```

## Recorrido extremo a extremo del kiosco

Cuando el operador usa la aplicacion desde la VM Windows, el flujo real es este:

1. la VM resuelve `kiosk.<namespace>.buytime.internal` via `hosts`
2. la solicitud se dirige a la IP privada del App Stack site
3. XC recibe el trafico en el HTTP load balancer `kiosk`
4. el load balancer selecciona el origin pool del kiosco
5. el origin pool enruta a `kiosk-service.<namespace>`
6. el pod `kiosk` actua como proxy hacia WordPress
7. WordPress obtiene datos desde MySQL
8. la respuesta vuelve al navegador de la VM

```mermaid
sequenceDiagram
    participant VM as Windows kiosk VM
    participant Hosts as hosts local
    participant Site as App Stack site IP
    participant LB as XC HTTP LB kiosk
    participant KS as kiosk-service
    participant KP as kiosk pod
    participant WS as wordpress-service
    participant WP as wordpress pod
    participant DB as mysql-service/mysql pod

    VM->>Hosts: Resolver kiosk.namespace.buytime.internal
    Hosts-->>VM: IP privada del App Stack site
    VM->>Site: GET / Host=kiosk.namespace.buytime.internal
    Site->>LB: Entregar solicitud al HTTP LB kiosk
    LB->>KS: Route request
    KS->>KP: Forward to kiosk pod
    KP->>WS: Proxy to wordpress-service
    WS->>WP: Forward to wordpress pod
    WP->>DB: Query MySQL
    DB-->>WP: Resultados
    WP-->>KP: HTML generado
    KP-->>LB: Respuesta proxied
    LB-->>VM: Pagina BuyTime
```

## Recorrido extremo a extremo del servicio de recomendaciones

El flujo de recomendaciones es distinto porque no termina dentro del mK8s del branch.

1. la VM o la aplicacion usa `recommendations.<namespace>.buytime.internal`
2. XC recibe la solicitud en el HTTP load balancer `recommendations`
3. ese load balancer usa un origin pool con `public_name`
4. el trafico sale hacia el servicio externo de recomendaciones por TLS

```mermaid
sequenceDiagram
    participant VM as Windows kiosk VM o app
    participant Hosts as hosts local
    participant Site as App Stack site IP
    participant LB as XC HTTP LB recommendations
    participant Pool as Origin pool recommendations
    participant EXT as External recommendations service

    VM->>Hosts: Resolver recommendations.namespace.buytime.internal
    Hosts-->>VM: IP privada del App Stack site
    VM->>Site: HTTP Host=recommendations.namespace.buytime.internal
    Site->>LB: Entregar solicitud al LB
    LB->>Pool: Seleccionar origin pool
    Pool->>EXT: TLS hacia DNS externo configurado
    EXT-->>VM: Respuesta del servicio de recomendaciones
```

## Mapa de correspondencia con la guia de referencia

Para evitar confusion, esta es la equivalencia entre la narrativa del repo original y lo que este workflow automatiza realmente.

- `Create mK8s resource`: si, lo crea o reutiliza
- `Create app stack`: si, lo crea
- `Get mK8s Kubeconfig`: si, lo genera de forma temporal durante el workflow
- `Create AWS CE site`: no, este workflow no lo implementa
- `Deploy kiosk`: si, mediante `module_1`
- `Create branch namespace`: si, lo crea o reutiliza desde Terraform y Kubernetes
- `Create HTTP LB for kiosk`: si
- `HTTP LB recommendations module`: si
- `Module 2`: no
- `Module 3`: no

## Conclusiones de topologia

La arquitectura que implementa este workflow es la de una **Retail Branch App Stack deployment** con estas propiedades clave:

- una sola sucursal en AWS
- un solo App Stack site
- un solo mK8s asociado al branch
- una VM de prueba dentro de la misma red del branch
- una aplicacion 3-tier en mK8s para el kiosco
- exposicion interna por HTTP LB de XC
- extension funcional hacia un servicio externo de recomendaciones

Eso la convierte en una automatizacion fiel al tramo inicial del escenario BuyTime, pero todavia acotada al branch y no al resto del diseño multicloud completo de la guia original.

## Job prerequisites

Este job prepara la base del entorno y publica outputs que el segundo job necesita.

### Paso a paso

1. Hace checkout del repositorio.
2. Configura Terraform con el token de Terraform Cloud.
3. Valida que existan las variables obligatorias.
4. Valida que `VPC_CIDR_MK8S` sea un CIDR valido.
5. Calcula los nombres de workspaces remotos a partir de `PROJECT_PREFIX` y `XC_NAMESPACE`.
6. Decodifica el certificado P12 de XC en un archivo temporal.
7. Verifica que el certificado cliente de XC no este expirado.
8. Inicializa el modulo `namespace-probe`.
9. Detecta si el namespace XC ya existe o si debe crearse.
10. Inicializa el modulo `prerequisites` usando Terraform Cloud.
11. Ejecuta `terraform apply` sobre `aws-mk8s-vk8s/prerequisites`.
12. Extrae outputs del estado remoto para usarlos en `module_1`.

### Diagrama del job prerequisites

```mermaid
flowchart TD
    A[Iniciar prerequisites] --> B[Validar variables y CIDR]
    B --> C[Calcular nombres de workspace]
    C --> D[Decodificar P12 de XC]
    D --> E[Validar expiracion del certificado]
    E --> F[terraform init namespace-probe]
    F --> G[Detectar si existe XC namespace]
    G --> H[terraform init prerequisites]
    H --> I[terraform apply prerequisites]
    I --> J[Recolectar outputs]
```

## Que crea prerequisites

El job `prerequisites` prepara la base del laboratorio. En terminos funcionales, deja listo lo siguiente:

- namespace XC, si aun no existe
- VPC y subnet en AWS
- App Stack site en XC sobre AWS
- mK8s del sitio, o reutiliza uno existente si se definio `EXISTING_MK8S_CLUSTER_NAME`
- VM Windows kiosk
- contraseña opcional de Windows mediante `PASSWORD_VM_WINDOWS`
- entradas del archivo `hosts` en la VM para `kiosk.<namespace>.buytime.internal` y `recommendations.<namespace>.buytime.internal`

## Job module_1

Este job depende de los outputs del job anterior y solo corre cuando `prerequisites` termina correctamente.

### Paso a paso

1. Hace checkout del repositorio.
2. Configura Terraform.
3. Configura `kubectl`.
4. Restaura el nombre del workspace de `module_1` usando el `workspace_prefix` generado en `prerequisites`.
5. Decodifica nuevamente el certificado P12 de XC.
6. Verifica que el certificado cliente de XC siga siendo valido.
7. Espera a que el App Stack site en XC entre en estado utilizable.
8. Inicializa el helper `kubeconfig`.
9. Crea una credencial temporal en XC y genera un kubeconfig del sitio.
10. Espera a que el API del mK8s responda correctamente.
11. Inicializa Terraform para `aws-mk8s-vk8s/module-1`.
12. Ejecuta `terraform apply` de `module_1`.
13. Si aparece el error transitorio `the server is currently unable to handle the request`, reintenta hasta 4 veces.
14. Revoca la credencial temporal de kubeconfig al final, incluso si hubo error.

### Diagrama del job module_1

```mermaid
flowchart TD
    A[Iniciar module_1] --> B[Preparar Terraform y kubectl]
    B --> C[Restaurar MODULE1_WORKSPACE]
    C --> D[Decodificar y validar P12 de XC]
    D --> E[Esperar readiness del App Stack site]
    E --> F[terraform init kubeconfig]
    F --> G[Crear credencial temporal y generar kubeconfig]
    G --> H[Esperar readiness del API de mK8s]
    H --> I[terraform init module-1]
    I --> J[terraform apply module-1]
    J --> K[Revocar credencial temporal]
    K --> L[Fin]
```

## Espera de readiness del App Stack site

Antes de aplicar `module_1`, el workflow consulta directamente la API de XC para confirmar que el sitio haya llegado a un estado adecuado.

Estados considerados listos:

- `ONLINE`
- `ORCHESTRATION_COMPLETE`
- `VALIDATION_SUCCESS`

Estados considerados terminales con error:

- `FAILED`
- `FAILED_INACTIVE`
- `ERROR_IN_ORCHESTRATION`
- `VALIDATION_FAILED`
- `ERROR_DELETING_CLOUD_RESOURCES`
- `ERROR_UPDATING_CLOUD_RESOURCES`

Esto evita intentar aplicar Kubernetes cuando el sitio aun no esta listo.

## Como obtiene acceso Kubernetes para aplicar module_1

El modulo `module_1` usa el provider `kubectl`, por lo que el workflow necesita un kubeconfig valido del sitio.

Para resolverlo, el job:

1. Usa el modulo `aws-mk8s-vk8s/kubeconfig`.
2. Intenta crear una credencial temporal con varios roles candidatos.
3. Si un rol no existe o esta deshabilitado, prueba el siguiente.
4. Si encuentra uno valido, genera un kubeconfig temporal.
5. Usa ese kubeconfig para validar el API de Kubernetes y luego hacer el apply de `module_1`.
6. Al final destruye la credencial temporal creada.

## Espera de readiness del mK8s API

Despues de obtener el kubeconfig, el workflow no asume que el cluster ya esta listo.

La verificacion de readiness hace dos pruebas:

- `kubectl cluster-info`
- `kubectl get namespace default -o name`

Solo cuando ambas funcionan se considera que el API ya esta usable para el provider `kubectl`.

## Reintentos en module_1

El deploy de `module_1` tiene manejo de errores transitorios del API de Kubernetes.

Si el log contiene el mensaje:

- `the server is currently unable to handle the request`

el workflow espera 30 segundos y vuelve a intentar, hasta un maximo de 4 intentos.

Esto reduce fallas intermitentes cuando el mK8s aun esta estabilizandose aunque ya responda.

### Diagrama del bloque de reintentos

```mermaid
flowchart TD
    A[Intentar terraform apply module-1] --> B{Apply exitoso?}
    B -->|Si| C[Fin exitoso]
    B -->|No| D{Error transitorio del API?}
    D -->|Si y quedan intentos| E[Esperar 30s]
    E --> A
    D -->|No| F[Terminar con error]
```

## Outputs que conectan ambos jobs

El job `prerequisites` publica estos outputs:

- `app_stack_name`
- `mk8s_cluster_name`
- `xc_namespace`
- `workspace_prefix`

El job `module_1` usa principalmente:

- `app_stack_name`
- `xc_namespace`
- `workspace_prefix`

## Consideraciones operativas

- El workflow usa Terraform Cloud workspaces calculados a partir de `PROJECT_PREFIX` y `XC_NAMESPACE`.
- Si `EXISTING_MK8S_CLUSTER_NAME` tiene valor, el deploy reutiliza un mK8s existente en lugar de crear uno nuevo.
- Si `PASSWORD_VM_WINDOWS` tiene valor valido, la VM kiosk fija esa contraseña en el primer arranque.
- La VM kiosk tambien escribe automaticamente el archivo `hosts` con los nombres internos del laboratorio.
- La credencial temporal usada para kubeconfig se revoca al final para no dejar acceso sobrante en XC.

## Resumen rapido

- `prerequisites` crea la base del entorno y publica outputs
- `module_1` espera readiness del sitio y del mK8s antes de aplicar
- el kubeconfig del sitio se genera de forma temporal
- el apply de `module_1` tiene reintentos para errores transitorios del API
- la credencial temporal se revoca siempre al terminar
