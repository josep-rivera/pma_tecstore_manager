# TecStore Manager — Documentación Técnica

## Índice
1. [Cómo está organizado el proyecto](#1-cómo-está-organizado-el-proyecto)
2. [Escenas en el Storyboard](#2-escenas-en-el-storyboard)
3. [Navegación](#3-navegación)
4. [Componentes UIKit por pantalla](#4-componentes-uikit-por-pantalla)
5. [Componentes SwiftUI por pantalla](#5-componentes-swiftui-por-pantalla)
6. [Arquitectura MVC y MVVM](#6-arquitectura-mvc-y-mvvm)
7. [Cómo leer el código](#7-cómo-leer-el-código)
8. [Flujo de la aplicación](#8-flujo-de-la-aplicación)
9. [Persistencia: UserDefaults y Core Data](#9-persistencia-userdefaults-y-core-data)

---

## 1. Cómo está organizado el proyecto

```
tecstore-manager/
├── App/                    AppDelegate, SceneDelegate, lifecycle
├── Assets.xcassets/        Imágenes, iconos y colores semánticos
├── Base.lproj/             Main.storyboard + LaunchScreen
├── Core/                   Extensiones, Theme, PasswordHasher, utilidades compartidas
├── CoreData/               NSManagedObject subclasses, PersistenceController, .xcdatamodeld
├── Services/               Toda la lógica de negocio, repositorios CoreData y helpers
├── SwiftUI/                Pantallas en SwiftUI (una carpeta por pantalla)
│   ├── Busquedas/
│   ├── Hosting/
│   ├── Inicio/
│   ├── Perfil/
│   ├── Reportes/
│   └── Ventas/
└── UIKit/                  ViewControllers en UIKit (una carpeta por feature)
    ├── Auth/
    ├── Clientes/
    ├── Menu/
    └── Productos/
```

### Principios que seguimos

- **Una carpeta por pantalla/feature**. Dentro de `SwiftUI/` y `UIKit/` cada pantalla tiene su propia carpeta.
- **Un archivo por responsabilidad**. Nunca mezclamos View + ViewModel en el mismo archivo.
- **Services como repositorios**. Toda lógica de persistencia, imágenes, geocoding, etc. vive en `Services/`, no dentro de los VCs ni ViewModels.
- **Auto Layout 100 % en storyboard** para UIKit. Los VCs no crean constraints por código.
- **Navegación principal por segues manuales** en `Main.storyboard`.

---

## 2. Escenas en el Storyboard

`Main.storyboard` contiene **26 escenas**. Las de tipo `UIHostingController` envuelven vistas SwiftUI y no tienen subvistas definidas en el storyboard — su contenido se configura en código.

| Escena | Tipo | Contenido en storyboard |
|---|---|---|
| Navigation Controller (auth) | `UINavigationController` | Root → BienvenidaVC |
| **Bienvenida** | `BienvenidaViewController` | Logo (2 capas), título, subtítulo, botones Iniciar sesión / Crear cuenta, footer label. Constraints completos. |
| **Login** | `LoginViewController` | ScrollView → logo, título, subtítulo, campos correo/contraseña con error labels, botones login/registrarse, seed label. Constraints completos. |
| **Registro** | `RegistroViewController` | ScrollView → logo, título, subtítulo, campos nombre/correo/contraseña/confirmar con error labels, botones registrarse/login. Constraints completos. |
| Menu View Controller | `MenuViewController` (UITabBarController) | 5 relationship segues a los 5 NavigationControllers. |
| Navigation Controller (×5) | `UINavigationController` | Uno por cada tab: Inicio, Productos, Clientes, Ventas, Configuración. |
| **Lista Productos** | `ListaProductosViewController` | TableView + UISegmentedControl (Todo/Con stock/Sin stock) + empty label. |
| **Formulario Producto** | `FormularioProductoViewController` | ScrollView → UIImageView foto, campos nombre/categoría/precio/stock, UISwitch estado. Constraints completos en storyboard. |
| **Detalle Producto** | `DetalleProductoViewController` | UIImageView foto, nombre label, card view con InfoRows. Constraints completos en storyboard. |
| **Lista Clientes** | `ListaClientesViewController` | TableView + empty label. |
| **Formulario Cliente** | `FormularioClienteViewController` | ScrollView → campos DNI/nombres/apellidos/teléfono/correo/dirección, UISwitch estado, MKMapView. Constraints completos en storyboard. |
| **Detalle Cliente** | `DetalleClienteViewController` | Card de contacto + MKMapView. Constraints completos en storyboard. |
| **Inicio** *(SwiftUI)* | `InicioViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `InicioView`. |
| **Lista Ventas** *(SwiftUI)* | `ListaVentasViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `ListaVentasView`. |
| **Configuración** *(SwiftUI)* | `PerfilViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `PerfilView`. |
| **Acerca De** *(SwiftUI)* | `AcercaDeViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `AcercaDeView`. |
| **Registro Venta** *(SwiftUI)* | `RegistroVentaViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `RegistroVentaView`. |
| **Detalle Venta** *(SwiftUI)* | `DetalleVentaViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `DetalleVentaView`. |
| **Búsquedas** *(SwiftUI)* | `BusquedasViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `BusquedasView`. |
| **Reportes** *(SwiftUI)* | `ReportesViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `ReportesView`. |
| **Stock Bajo** *(SwiftUI)* | `StockBajoViewController` (UIHostingController) | Solo contenedor vacío. Contenido: `StockBajoView`. |

---

## 3. Navegación

### Storyboard — action segues (sin identifier)
Disparados directamente por botones o celdas en IB:

| Origen | Destino | Disparador |
|---|---|---|
| Bienvenida | Login | Botón "Iniciar sesión" |
| Bienvenida | Registro | Botón "Crear cuenta" |
| Login | Registro | Botón "Crear cuenta nueva" |
| Lista Productos | Detalle Producto | Tap en celda |
| Detalle Producto | Formulario Producto (editar) | Botón "Editar" |
| Lista Productos | Formulario Producto (nuevo) | Botón "+" nav bar |
| Lista Clientes | Detalle Cliente | Tap en celda |
| Detalle Cliente | Formulario Cliente (editar) | Botón "Editar" |
| Lista Clientes | Formulario Cliente (nuevo) | Botón "+" nav bar |

### Storyboard — segues con identifier
Disparados desde código con `performSegue(withIdentifier:)`. Necesario porque el disparador está dentro de una vista SwiftUI que no puede conectarse directamente en IB:

| Identifier | Origen | Destino | Tipo |
|---|---|---|---|
| `showAcercaDe` | PerfilViewController | AcercaDeViewController | show |
| `showBusquedas` | InicioViewController | BusquedasViewController | show |
| `showReportes` | InicioViewController | ReportesViewController | show |
| `showStockBajo` | InicioViewController | StockBajoViewController | show |
| `showNuevaVentaModal` | InicioViewController | RegistroVentaViewController | **modal** |
| `showRegistroVenta` | ListaVentasViewController | RegistroVentaViewController | show |
| `showDetalleVenta` | ListaVentasViewController | DetalleVentaViewController | show |

### Programático (necesario — sin alternativa en storyboard)
| Acción | Dónde | Por qué |
|---|---|---|
| Reemplazar root con MenuViewController post-login | `SceneDelegate.switchToMenu()` | Cambiar el root VC de la ventana no tiene equivalente en storyboard |
| Reemplazar root con BienvenidaVC post-logout | `SceneDelegate.switchToAuth()` | Ídem |

### Back navigation — siempre código
`popViewController(animated:)` en Formulario Producto, Formulario Cliente y Registro. `dismiss()` en sheets SwiftUI. Esto es estándar en UIKit/SwiftUI — no existe "segue de vuelta" en storyboard.

---

## 4. Componentes UIKit por pantalla

| Componente | Pantalla(s) |
|---|---|
| `UILabel` | Todas las pantallas UIKit |
| `UITextField` | Login, Registro, Formulario Producto, Formulario Cliente |
| `UIButton` | Bienvenida, Login, Registro |
| `UITableView` | Lista Productos, Lista Clientes |
| `UISegmentedControl` | Lista Productos (filtro Todo / Con stock / Sin stock) |
| `UISwitch` | Formulario Producto (estado activo/inactivo), Formulario Cliente (estado) |
| `UIImageView` | Bienvenida (logo), Login (logo), Registro (logo), Detalle Producto (foto), Formulario Producto (foto) |
| `UIAlertController` | Todos los VCs vía extensión `UIViewController.showAlert(...)` |
| `UINavigationController` | Root del flujo auth + los 5 nav controllers de las tabs |
| `MKMapView` | Formulario Cliente (interactivo), Detalle Cliente (solo lectura) |

**Layout de celdas (código):** `ProductoCell` y `ClienteCell` son prototype cells registradas en el storyboard (clase + reuseIdentifier), pero su layout interno (subvistas, constraints, estilos) se construye 100% en `buildUI()` — el storyboard no define ninguna subvista dentro de ellas.

---

## 5. Componentes SwiftUI por pantalla

| Componente | Pantalla(s) |
|---|---|
| `Text` | Todas las vistas SwiftUI |
| `TextField` | Búsquedas, Registro Venta |
| `Button` | Todas las vistas SwiftUI |
| `List` | Inicio (stock bajo), Búsquedas (resultados), Lista Ventas |
| `Form` | Configuración (PerfilView), Acerca De, Cambiar Contraseña |
| `Toggle` | Configuración (modo oscuro) |
| `Picker` | Búsquedas, Registro Venta |
| `DatePicker` | Búsquedas, Lista Ventas |
| `Map` | Búsquedas (mapa de clientes) |
| `.sheet` | Lista Ventas (filtro), Registro Venta (confirmación), Configuración (cambiar contraseña), Búsquedas (detalle) |
| `NavigationStack` | Cambiar Contraseña sheet, Registro Venta sheet, Búsquedas sheets |

**Integración con UIKit:** todas las vistas SwiftUI se montan en un `UIHostingController` que actúa como contenedor UIKit dentro del `UINavigationController` de la tab correspondiente.

---

## 6. Arquitectura MVVM

El proyecto aplica MVVM de forma consistente en todas las pantallas. El patrón varía levemente según el framework (UIKit vs SwiftUI), pero el rol de cada capa es el mismo.

### MVVM — pantallas UIKit

El ViewModel expone closures (outputs) que el ViewController implementa para actualizar la UI. El ViewController solo llama métodos del ViewModel (inputs) y nunca accede a los Services directamente.

```
viewWillAppear → viewModel.loadData()
    → ClienteService.shared.fetchAll()  (dentro del ViewModel, CoreData síncrono)
    → viewModel.onReload?()             (output al VC)
    → tableView.reloadData()            (el VC actualiza la UI)
```

Paso de datos entre VCs mediante `prepare(for:sender:)`:
```swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let dest = segue.destination as? DetalleClienteViewController {
        guard let ip = tableView.indexPathForSelectedRow else { return }
        dest.cliente = viewModel.filteredClientes[ip.row]
    }
}
```

### MVVM — pantallas SwiftUI

El ViewModel expone `@Published` properties; la vista se suscribe automáticamente con `@ObservedObject`. Todos los Services son **síncronos** — no hay `async/await` en los ViewModels (salvo `PhotosPickerItem.loadTransferable` que es una API nativa de Apple sin alternativa sync).

```
RegistroVentaView (@ObservedObject viewModel)
    → viewModel.selectedCliente = c          // mutación
    → viewModel.$cartItems (Publisher)       // SwiftUI re-renderiza
    → VentaService.shared.register(...)      // persiste en CoreData (sync throws)
```

Ejemplo concreto de `ListaVentasViewModel`:
```swift
@MainActor
final class ListaVentasViewModel: ObservableObject {
    @Published var ventas: [Venta] = []

    func loadAll() {
        ventas = VentaService.shared.fetchAll()
    }
}
```

`ListaVentasView` solo lee `viewModel.ventas` y llama `viewModel.loadAll()` en `.onAppear` — sin lógica de negocio.

### MVVM — pantallas UIKit complejas

Las pantallas con formularios y validación (`FormularioProducto`, `FormularioCliente`, `Login`, `Registro`) usan MVVM. El ViewModel expone closures que el VC implementa para actualizar la UI.

```swift
// RegistroViewController.swift
private func bindViewModel() {
    viewModel.onValidationErrors = { [weak self] validation in
        self?.apply(validation: validation)
    }
    viewModel.onLoading = { [weak self] isLoading in
        self?.registerButton.isEnabled = !isLoading
        self?.registerButton.alpha = isLoading ? 0.6 : 1
    }
    viewModel.onError = { [weak self] message in
        self?.showAlert(title: "Error al registrarse", message: message)
    }
    viewModel.onSuccess = {
        (UIApplication.shared.connectedScenes.first?.delegate as? SceneDelegate)?.switchToMenu()
    }
}
```

### ViewModels existentes

| ViewModel | Vista/VC | Framework |
|---|---|---|
| `ListaClientesViewModel` | `ListaClientesViewController` | UIKit |
| `DetalleClienteViewModel` | `DetalleClienteViewController` | UIKit |
| `FormularioClienteViewModel` | `FormularioClienteViewController` | UIKit |
| `ListaProductosViewModel` | `ListaProductosViewController` | UIKit |
| `DetalleProductoViewModel` | `DetalleProductoViewController` | UIKit |
| `FormularioProductoViewModel` | `FormularioProductoViewController` | UIKit |
| `LoginViewModel` | `LoginViewController` | UIKit |
| `RegistroViewModel` | `RegistroViewController` | UIKit |
| `InicioViewModel` | `InicioView` | SwiftUI |
| `StockBajoViewModel` | `StockBajoView` | SwiftUI |
| `ListaVentasViewModel` | `ListaVentasView` | SwiftUI |
| `RegistroVentaViewModel` | `RegistroVentaView` | SwiftUI |
| `DetalleVentaViewModel` | `DetalleVentaView` | SwiftUI |
| `PerfilViewModel` | `PerfilView` | SwiftUI |
| `ReportesViewModel` | `ReportesView` | SwiftUI |
| `BusquedasViewModel` | `BusquedasView` | SwiftUI |

---

## 7. Cómo leer el código

### Si vas a tocar una pantalla SwiftUI
1. Abre `SwiftUI/<Feature>/`.
2. Lee primero el `*ViewModel.swift`: ahí está el estado y la lógica.
3. Luego lee el `*View.swift`: es puro layout declarativo.
4. Si la pantalla se muestra desde UIKit, busca su `UIHostingController` en `SwiftUI/Hosting/HostingControllers.swift`.

### Si vas a tocar una pantalla UIKit
1. Abre `UIKit/<Feature>/`.
2. Si la pantalla es un formulario/auth, lee primero el `*ViewModel.swift`.
3. Luego lee el `*ViewController.swift`: solo configura outlets, actions y bindings.
4. El diseño visual está en `Main.storyboard`.

### Si vas a tocar persistencia o reglas de negocio
1. Ve a `CoreData/` para ver los `NSManagedObject` y el `PersistenceController`.
2. Ve a `Services/` para ver la lógica de cada dominio.
3. Los Services actúan como repositorios: la UI nunca toca Core Data directamente.

### Convenciones de nombres
- Vistas SwiftUI: `<Nombre>View`
- ViewModels: `<Nombre>ViewModel`
- ViewControllers UIKit: `<Nombre>ViewController`
- Services: `<Dominio>Service`
- Entidades CoreData: nombre en PascalCase sin prefijo (`Producto`, `Cliente`, `Venta`, etc.)

---

## 8. Flujo de la aplicación

```
Lanzamiento
    └─ SceneDelegate.scene(_:willConnectTo:)
          ├─ AppStyle.configureGlobalAppearance()
          ├─ AuthService.hasActiveSession?   (UserDefaults "activeUserID")
          │       ├─ YES → MenuViewController (UITabBarController)
          │       └─ NO  → UINavigationController → BienvenidaViewController
          └─ SeederService.seedIfNeeded()
                   └─ solo en primer lanzamiento (flag en UserDefaults)

Auth
    BienvenidaVC ──(segue)──► LoginVC ──(segue)──► RegistroVC
                                 │
                         viewModel.login() / viewModel.register()
                                 │
                         SceneDelegate.switchToMenu()  ←─ cross-dissolve

Menu (5 tabs)
    Inicio      → Reportes / Búsquedas / Stock Bajo / Nueva Venta (segues con id)
    Productos   → Detalle → Formulario (segues sin id)
    Clientes    → Detalle → Formulario (segues sin id)
    Ventas      → Detalle / Nuevo Registro (segues con id)
    Configuración → Acerca De (segue "showAcercaDe")

Logout
    PerfilView → NotificationCenter.post(.userDidLogout)
    SceneDelegate.handleLogout() → AuthService.logout() → switchToAuth()
```

---

## 9. Persistencia: UserDefaults y Core Data

### UserDefaults
Se usa para **preferencias y estado de sesión únicamente**:

| Key | Tipo | Uso |
|---|---|---|
| `"activeUserID"` | `String` | ID del usuario con sesión activa. Si existe → `hasActiveSession = true`. Se setea al login, se elimina al logout. |
| `"darkModeEnabled"` | `Bool` | Preferencia de modo oscuro. Se lee en `SceneDelegate` al lanzar y se aplica con `window.overrideUserInterfaceStyle`. |
| `"seederCompleted_v6"` | `Bool` | Guard del seeder. Evita reinsertar datos de prueba en cada lanzamiento. |

UserDefaults **no almacena datos de negocio** — solo preferencias y estado de sesión liviano.

### Core Data

Modelo: `tecstore_tecsup.xcdatamodeld`. Cinco entidades persistentes con `NSManagedObject` escritos a mano (sin generación automática de Xcode):

| Entidad | Atributos clave | Relaciones |
|---|---|---|
| `Usuario` | id, fullName, email, passwordHash, passwordSalt, registrationDate, profileImagePath | — |
| `Producto` | id, code, name, category, price, stock, registrationDate, isActive, photoPath | — |
| `Cliente` | id, dni, firstName, lastName, phone, email, address, isActive | → `Ubicacion` (opcional) |
| `Venta` | id, date, subtotal, igv, total | → `Cliente`, → `[DetalleVenta]` |
| `DetalleVenta` | id, quantity, unitPrice, subtotal | → `Producto` |
| `Ubicacion` | id, latitude, longitude, referenceAddress, registrationDate | — |

**`PersistenceController`** es el singleton que expone:
- `viewContext` — para lectura en el hilo principal
- `backgroundContext` — para escritura sin bloquear la UI
- Métodos utilitarios: `fetch<T>()`, `count<T>()`, `delete(_:)`

### Autenticación

No hay Firebase Auth. La autenticación es local:
- El registro hashea la contraseña con SHA-256 + salt via `PasswordHasher` (`Core/PasswordHasher.swift`).
- El login busca el `Usuario` por email y compara el hash.
- La sesión activa se persiste en `UserDefaults["activeUserID"]`.

### Capa de Services (`Services/`)

Cada dominio tiene su propio Service que usa `PersistenceController` internamente. Los VCs y ViewModels los llaman sin preocuparse por Core Data directamente.

| Service | Responsabilidad |
|---|---|
| `AuthService` | Registro, login, logout, sesión activa, cambio de contraseña |
| `ProductoService` | CRUD de productos, generación de código, filtros por categoría/stock |
| `ClienteService` | CRUD de clientes, búsqueda por DNI, filtro por estado |
| `VentaService` | Registro de ventas, cálculo de totales (subtotal + 18% IGV), consulta por rango de fechas |
| `ReporteService` | Métricas agregadas: totales, ingresos por categoría, productos top, tendencia diaria |
| `UbicacionService` | Guardar y leer coordenadas GPS del cliente |
| `SeederService` | Datos de prueba en primer lanzamiento |
| `ProductoImageService` | Captura/redimensiona/guarda la foto de un producto en el directorio Documents |
| `ClienteLocationService` | Geocoding/reverse-geocoding con MapKit (`MKGeocodingRequest` / `MKReverseGeocodingRequest`) |

---

## Historial de cambios recientes

- **Migración completa de UI a CoreData**: todas las pantallas (Views y ViewControllers) que referenciaban tipos Firebase (`FBProducto`, `FBCliente`, `FBVenta`, `FBUsuario`) fueron adaptadas a los tipos CoreData (`Producto`, `Cliente`, `Venta`, `Usuario`).
- **Eliminación de async/await en la capa de presentación**: todos los ViewModels y ViewControllers pasaron de patrones `Task { try? await ... }` a llamadas síncronas directas. Los Services CoreData son síncronos.
- **MVVM completo en SwiftUI**: cada pantalla SwiftUI tiene su ViewModel inyectado desde `UIHostingController`.
- **MVVM en formularios UIKit**: `FormularioProducto`, `FormularioCliente`, `Login` y `Registro` usan ViewModels con closures.
- **Nuevas pantallas SwiftUI**: `StockBajoView`, `AcercaDeView`, `DetalleVentaView` y sus ViewModels.
- **Nuevos services de soporte**: `ProductoImageService` (camera/gallery + Documents) y `ClienteLocationService` (MapKit geocoding).
- **Auto Layout puro en storyboard**: los constraints de UIKit se movieron de código a `Main.storyboard`.
- **Navegación por segues**: unificación de transiciones con `performSegue` y segues manuales.
- **Geocoding moderno**: reemplazo de `CLGeocoder` deprecado por `MKGeocodingRequest` / `MKReverseGeocodingRequest`.
- **Colores semánticos**: celdas y tarjetas usan `secondarySystemBackground` para contrastar con el fondo en claro y oscuro.
