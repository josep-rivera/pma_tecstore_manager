import CoreData

// ─────────────────────────────────────────────
// MARK: - PersistenceController
// ─────────────────────────────────────────────

/// Single source of truth for the Core Data stack.
/// All reads use `viewContext`; all writes go through a background context.
final class PersistenceController {

    // MARK: - Singleton

    static let shared = PersistenceController()

    // MARK: - Container & Contexts

    let container: NSPersistentContainer

    /// Main-thread context — use for all UI reads and lightweight writes.
    var viewContext: NSManagedObjectContext { container.viewContext }

    // MARK: - Initialiser

    init(inMemory: Bool = false) {
        container = NSPersistentContainer(name: "tecstore_tecsup")

        if inMemory {
            // /dev/null → in-memory store; used for previews and unit tests
            let desc = NSPersistentStoreDescription()
            desc.url = URL(fileURLWithPath: "/dev/null")
            container.persistentStoreDescriptions = [desc]
        }

        container.loadPersistentStores { _, error in
            if let error {
                // Academic project: crash early on load failure so the issue
                // is immediately visible during development.
                fatalError("Core Data failed to load persistent stores: \(error.localizedDescription)")
            }
        }

        // Background saves automatically appear in the viewContext.
        container.viewContext.automaticallyMergesChangesFromParent = true
        // Last-writer wins; avoids conflicts when the UI and background
        // context write to the same object concurrently.
        container.viewContext.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
    }

    // MARK: - Save

    /// Save the viewContext if it has uncommitted changes.
    func save() {
        viewContext.saveIfNeeded()
    }

    // MARK: - Background Context

    /// Returns a new background context ready for write operations.
    /// Caller is responsible for calling `context.saveIfNeeded()` when done.
    func newBackgroundContext() -> NSManagedObjectContext {
        let ctx = container.newBackgroundContext()
        ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
        return ctx
    }

    /// Execute a block on a private-queue background context.
    /// The context is saved automatically after the block returns.
    ///
    /// - Parameter block: receives the background context; run your writes here.
    func performBackground(_ block: @escaping (NSManagedObjectContext) -> Void) {
        container.performBackgroundTask { ctx in
            ctx.mergePolicy = NSMergeByPropertyObjectTrumpMergePolicy
            block(ctx)
            ctx.saveIfNeeded()
        }
    }

    // MARK: - Fetch Utilities (viewContext)

    /// Execute a fetch request against the viewContext.
    /// Returns an empty array on error instead of throwing.
    func fetch<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> [T] {
        (try? viewContext.fetch(request)) ?? []
    }

    /// Count matching records without fetching the objects.
    func count<T: NSManagedObject>(_ request: NSFetchRequest<T>) -> Int {
        (try? viewContext.count(for: request)) ?? 0
    }

    /// True if at least one record exists for the given entity name.
    func hasData(for entityName: String) -> Bool {
        let req = NSFetchRequest<NSManagedObject>(entityName: entityName)
        req.fetchLimit = 1
        return ((try? viewContext.count(for: req)) ?? 0) > 0
    }

    /// Delete all records for a given entity name (useful for testing/reset).
    func deleteAll(entityName: String) {
        let req = NSFetchRequest<NSFetchRequestResult>(entityName: entityName)
        let batch = NSBatchDeleteRequest(fetchRequest: req)
        batch.resultType = .resultTypeObjectIDs

        if let result = try? viewContext.execute(batch) as? NSBatchDeleteResult,
           let objectIDs = result.result as? [NSManagedObjectID] {
            let changes = [NSDeletedObjectsKey: objectIDs]
            NSManagedObjectContext.mergeChanges(fromRemoteContextSave: changes, into: [viewContext])
        }
    }

    // MARK: - Preview / Testing

    /// In-memory stack pre-loaded with no data.
    /// Use in SwiftUI `#Preview` blocks and unit tests.
    static let preview: PersistenceController = {
        PersistenceController(inMemory: true)
    }()
}
