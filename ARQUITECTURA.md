# TecStore Manager — Documentación Técnica

## Índice
1. [Escenas en el Storyboard](#1-escenas-en-el-storyboard)
2. [Navegación](#2-navegación)
3. [Componentes UIKit por pantalla](#3-componentes-uikit-por-pantalla)
4. [Componentes SwiftUI por pantalla](#4-componentes-swiftui-por-pantalla)
5. [Arquitectura MVC y MVVM](#5-arquitectura-mvc-y-mvvm)
6. [Flujo de la aplicación](#6-flujo-de-la-aplicación)
7. [UserDefaults y Core Data](#7-userdefaults-y-core-data)

---

## 1. Escenas en el Storyboard

`Main.storyboard` contiene **26 escenas**. Las de tipo `UIHostingController` envuelven vistas SwiftUI y no tienen subvistas definidas en el storyboard — su contenido se configura en código.

| Escena | Tipo | Contenido en storyboard |
|---|---|---|
| Navigation Controller (auth) | `UINavigationController` | Root → BienvenidaVC |
| **Bienvenida** | `BienvenidaViewController` | Logo (2 capas), título, subtítulo, botones Iniciar sesión / Crear cuenta, footer label. Constraints completos. |
| **Login** | `LoginViewController` | ScrollView → logo, título, subtítulo, campos correo/contraseña con error labels, botones login/registrarse, seed label. Constraints completos. |
| **Registro** | `RegistroViewController` | ScrollView → logo, título, subtítulo, campos nombre/correo/contraseña/confirmar con error labels, botones registrarse/login. Constraints completos. |
| Menu View Controller | `MenuViewController` (UITabBarController) | 5 relationship segues a los 5 NavigationControllers. |
| Navigation Controller (×5) | `UINavigationController` | Uno por cada tab: Inicio, Productos, Clientes, Ventas, Configuración. |
| **Lista Productos** | `ListaProductosViewController` | TableView + UISegmentedControl (Todo/Activos/Stock bajo) + empty label. |
| **Formulario Producto** | `FormularioProductoViewController` | ScrollView → UIImageView foto, campos nombre/categoría/precio/stock, UISwitch estado. Error labels y vistas de estado construidas en código. |
| **Detalle Producto** | `DetalleProductoViewController` | UIImageView foto, nombre label, card view con separadores. Filas de info (código, stock, estado, categoría, fecha) construidas en código. |
| **Lista Clientes** | `ListaClientesViewController` | TableView + empty label. |
| **Formulario Cliente** | `FormularioClienteViewController` | ScrollView → campos DNI/nombres/apellidos/teléfono/correo/dirección, UISwitch estado, MKMapView. Error labels construidas en código. |
| **Detalle Cliente** | `DetalleClienteViewController` | Vistas de contacto y MKMapView construidas en código; card container en storyboard. |
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

## 2. Navegación

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

| Identifier | Origen | Destino |
|---|---|---|
| `showAcercaDe` | PerfilViewController | AcercaDeViewController |
| `showBusquedas` | InicioViewController | BusquedasViewController |
| `showReportes` | InicioViewController | ReportesViewController |
| `showStockBajo` | InicioViewController | StockBajoViewController |
| `showNuevaVentaModal` | InicioViewController | RegistroVentaViewController |
| `showRegistroVenta` | ListaVentasViewController | RegistroVentaViewController |
| `showDetalleVenta` | ListaVentasViewController | DetalleVentaViewController |

### Programático (necesario — sin alternativa en storyboard)
| Acción | Dónde | Por qué |
|---|---|---|
| Reemplazar root con MenuViewController post-login | `SceneDelegate.switchToMenu()` | Cambiar el root VC de la ventana no tiene equivalente en storyboard |
| Reemplazar root con BienvenidaVC post-logout | `SceneDelegate.switchToAuth()` | Ídem |

### Back navigation — siempre código
`popViewController(animated:)` en Formulario Producto, Formulario Cliente y Registro. `dismiss()` en sheets SwiftUI. Esto es estándar en UIKit/SwiftUI — no existe "segue de vuelta" en storyboard.

---

## 3. Componentes UIKit por pantalla

| Componente | Pantalla(s) |
|---|---|
| `UILabel` | Todas las pantallas UIKit |
| `UITextField` | Login, Registro, Formulario Producto, Formulario Cliente |
| `UIButton` | Bienvenida, Login, Registro |
| `UITableView` | Lista Productos, Lista Clientes |
| `UISegmentedControl` | Lista Productos (filtro Todo / Activos / Stock bajo) |
| `UISwitch` | Formulario Producto (estado activo/inactivo), Formulario Cliente (estado) |
| `UIImageView` | Bienvenida (logo), Login (logo), Registro (logo), Detalle Producto (foto), Formulario Producto (foto) |
| `UIAlertController` | Todos los VCs vía extensión `UIViewController.showAlert(...)` |
| `UINavigationController` | Root del flujo auth + los 5 nav controllers de las tabs |
| `MKMapView` | Formulario Cliente (interactivo), Detalle Cliente (solo lectura) |

**Layout de celdas (código):** `ProductoCell` y `ClienteCell` son prototype cells registradas en el storyboard (clase + reuseIdentifier), pero su layout interno (subvistas, constraints, estilos) se construye 100% en `buildUI()` — el storyboard no define ninguna subvista dentro de ellas.

---

## 4. Componentes SwiftUI por pantalla

| Componente | Pantalla(s) |
|---|---|
| `Text` | Todas las vistas SwiftUI |
| `TextField` | Registro Venta (búsqueda de producto) |
| `Button` | Todas las vistas SwiftUI |
| `List` | Inicio (stock bajo), Búsquedas (resultados) |
| `Form` | Configuración (PerfilView), Acerca De, Cambiar Contraseña |
| `Toggle` | Configuración (modo oscuro) |
| `Picker` | Registro Venta (selector de cliente) |
| `DatePicker` | Lista Ventas (filtro por rango de fechas) |
| `Map` | Búsquedas (mapa de clientes) |
| `.sheet` | Lista Ventas (filtro), Registro Venta (confirmación), Configuración (cambiar contraseña), Búsquedas (detalle) |
| `NavigationStack` | Cambiar Contraseña sheet, Registro Venta sheet, Búsquedas sheets |

**Integración con UIKit:** todas las vistas SwiftUI se montan en un `UIHostingController` que actúa como contenedor UIKit dentro del `UINavigationController` de la tab correspondiente.

---

## 5. Arquitectura MVC y MVVM

### MVC — pantallas UIKit

El ViewController es el Controller: recibe eventos de la UI, llama directamente al Service, y actualiza la vista.

```
UIButton (tap) → LoginViewController.handleLogin()
    → AuthService.shared.login(email:password:)   ← Model (Service + CoreData)
    → SceneDelegate.switchToMenu()                ← actualiza Vista (root VC)
```

Otro ejemplo — paso de datos entre VCs:
```swift
// ListaClientesViewController.swift
override func prepare(for segue: UIStoryboardSegue, sender: Any?) {
    if let dest = segue.destination as? DetalleClienteViewController,
       let cliente = sender as? Cliente {
        dest.cliente = cliente   // el VC destino recibe el modelo directamente
    }
}
```

Los VCs NO tienen ViewModel: consultan el Service y renderizan. Ejemplo en Lista Productos:
```swift
productos = ProductoService.shared.fetchAll()  // llama al modelo
tableView.reloadData()                          // actualiza la vista
```

### MVVM — pantallas SwiftUI

El ViewModel expone `@Published` properties; la vista se suscribe automáticamente con `@StateObject`.

```
RegistroVentaView (@StateObject viewModel)
    → viewModel.selectedCliente = c          // mutación
    → viewModel.$cart (Publisher)            // SwiftUI re-renderiza
    → VentaService.shared.register(...)      // Model
```

Ejemplo concreto de `ListaVentasViewModel`:
```swift
@MainActor
final class ListaVentasViewModel: ObservableObject {
    @Published var ventas: [Venta] = []
    @Published var isDateFiltering = false

    func load() {
        ventas = VentaService.shared.fetchAll()
    }
}
```

`ListaVentasView` solo lee `viewModel.ventas` y llama `viewModel.load()` — sin lógica de negocio.

### ViewModels existentes

| ViewModel | Vista |
|---|---|
| `InicioViewModel` | `InicioView` |
| `ListaVentasViewModel` | `ListaVentasView` |
| `RegistroVentaViewModel` | `RegistroVentaView` |
| `PerfilViewModel` | `PerfilView` (Configuración) |
| `ReportesViewModel` | `ReportesView` |
| `BusquedasViewModel` | `BusquedasView` |

---

## 6. Flujo de la aplicación

```
Lanzamiento
    └─ SceneDelegate.scene(_:willConnectTo:)
          ├─ SeederService.seedIfNeeded()      ← datos iniciales (solo 1ra vez)
          ├─ AppStyle.configureGlobalAppearance()
          └─ AuthService.hasActiveSession?
                ├─ YES → MenuViewController (UITabBarController)
                └─ NO  → UINavigationController → BienvenidaViewController

Auth
    BienvenidaVC ──(segue)──► LoginVC ──(segue)──► RegistroVC
                                │
                        handleLogin() → AuthService.login()
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
    SceneDelegate.handleLogout() → switchToAuth()
```

---

## 7. UserDefaults y Core Data

### UserDefaults
Se usa para **dos propósitos únicamente**:

| Key | Tipo | Uso |
|---|---|---|
| `"activeUserID"` | `String` | ID del usuario con sesión activa. Si existe → `hasActiveSession = true`. Se setea al login, se elimina al logout. |
| `"darkModeEnabled"` | `Bool` | Preferencia de modo oscuro. Se lee en `SceneDelegate` al lanzar y se aplica con `window.overrideUserInterfaceStyle`. |
| `"seederCompleted_v6"` | `Bool` | Guard del seeder. Evita reinsertar datos de prueba en cada lanzamiento. |

UserDefaults **no almacena datos de negocio** — solo preferencias y estado de sesión liviano.

### Core Data
Cinco entidades persistentes con `NSManagedObject` escritos a mano (sin generación automática de Xcode):

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

**Justificación de la separación Services/CoreData:** los `NSManagedObject` no se exponen directamente a la UI. Los `Services` (AuthService, ProductoService, etc.) actúan como repositorios: reciben/devuelven los managed objects pero encapsulan los `NSPredicate`, el `NSFetchRequest` y el `context.save()`. La UI nunca toca Core Data directamente.
