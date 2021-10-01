//
//  ALDBHandler.h
//  ChatApp
//
//  Created by Gaurav Nigam on 09/08/15.
//  Copyright (c) 2015 AppLogic. All rights reserved.
//

#import <Foundation/Foundation.h>
#import <CoreData/CoreData.h>

/// `ALDBHandler` has all the methods for core data operations like inserting, fetching, deleting and updating in core data ManagedObject.
/// @warning `ALDBHandler` class used only for internal purposes.
@interface ALDBHandler : NSObject

/// `managedObjectModel` is used in `NSPersistentContainer` init method to configure.
@property (readonly, strong, nonatomic) NSManagedObjectModel *managedObjectModel;

/// `persistentContainer` is has a access for performing operations in core data.
@property (strong, nonatomic) NSPersistentContainer *persistentContainer;

/// To check if the NSPersistentContainer is loaded successfully or not.
@property (nonatomic) BOOL isStoreLoaded;

/// To save the main ManagedObject context in core data.
- (NSError *)saveContext;

/// Shared instance method of `ALDBHandler`.
+ (ALDBHandler *)sharedInstance;

/// Use this method for save the private managed object context  and main managed object context in core data.
/// @param context Pass the private context.
/// @param completion Handler will have error in case of failed to save else error will be nil in case of success save.
- (void)saveWithContext:(NSManagedObjectContext *)context
             completion:(void (^)(NSError *error))completion;

/// Fetching the data from core database this will require `NSFetchRequest` object for Processing.
/// @param fetchrequest Create a fetch request for fetching array of data.
/// @param fetchError Pass the `NSError` to check the status of fetch request.
- (NSArray *)executeFetchRequest:(NSFetchRequest *)fetchrequest withError:(NSError **)fetchError;

/// Entities describe the "types" of objects available.
/// @param name Pass the name of the entity.
- (NSEntityDescription *)entityDescriptionWithEntityForName:(NSString *)name;

/// Gets Result count for fetch request.
/// @param fetchrequest Fetch request to get the count of objects.
- (NSUInteger)countForFetchRequest:(NSFetchRequest *)fetchrequest;

/// To get the `NSManagedObject` by `NSManagedObjectID` from core data.
/// @param objectID Pass the `ManagedObjectID`.
- (NSManagedObject *)existingObjectWithID:(NSManagedObjectID *)objectID;

/// Insert new object in main context for entity name given.
/// @param entityName Pass the name of the entity that data as to be inserted.
- (NSManagedObject *)insertNewObjectForEntityForName:(NSString *)entityName;

/// Insert new object in private context for entity name given.
/// @param entityName Pass the name of entity.
/// @param context Pass the context to insert the object.
- (NSManagedObject *)insertNewObjectForEntityForName:(NSString *)entityName withManagedObjectContext:(NSManagedObjectContext *)context;

/// Deletes the managed object from core database.
/// @param managedObject Pass themanaged object that you want to delete from core data.
- (void)deleteObject:(NSManagedObject *)managedObject;

/// Used for performing batch update in core data.
/// @param updateRequest Pass the batch update request.
/// @param fetchError Pass the error in case of any error the object will not be nil else it will be nil in case of success update.
/// @return Returns the NSBatchUpdateResult in case of updated otherwise nil.
- (NSBatchUpdateResult *)executeRequestForNSBatchUpdateResult:(NSBatchUpdateRequest *)updateRequest withError:(NSError **)fetchError;

@end
