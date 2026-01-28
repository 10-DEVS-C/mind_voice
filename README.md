# mind_voice

A new Flutter project.

lib/
├── core/                # Funcionalidades compartidas por toda la app
│   ├── constants/       # Colores, strings, dimensiones fijas
│   ├── errors/          # Manejo de excepciones y fallos
│   ├── network/         # Configuración de clientes HTTP (Dio, etc.)
│   ├── theme/           # Estilos globales y temas (Dark/Light)
│   └── utils/           # Validadores, extensiones de formato
│
├── config/              # Configuración global
│   ├── routes/          # Gestión de navegación y nombres de rutas
│   │   ├── app_routes.dart
│   │   └── route_handlers.dart
│   └── service_locator.dart # Inyección de dependencias
│
├── features/            # División por módulos funcionales
│   ├── home/            # Ejemplo de una funcionalidad: Inicio
│   │   ├── data/        # Repositorios, modelos y fuentes de datos
│   │   ├── domain/      # Entidades y casos de uso (Lógica de negocio)
│   │   └── presentation/# UI: Widgets, Pages y manejadores de estado
│   │       ├── pages/
│   │       ├── widgets/
│   │       └── provider/ (o bloc/cubit)
│   │
│   └── auth/            # Ejemplo: Autenticación (Login, Registro)
│       ├── data/
│       ├── domain/
│       └── presentation/
│
├── shared/              # Widgets que se usan en múltiples features
│   └── widgets/         # Custom Buttons, TextFields, etc.
│
└── main.dart            # Punto de entrada de la aplicación