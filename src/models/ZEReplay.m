#import "ZEReplay.h"
#import "ze_mpq.h"
#import "ZEMap.h"
#import "ZEReplayPlayer.h"
#import "ZEPlayer.h"
#import "ZEAppDelegate.h"

@interface ZEReplay ()
- (ZEPlayer *)findPlayerWithId:(NSString *)bnetId inRegion:(NSString *)region;
- (ZEMap *)findMap:(NSString *)name;
- (ZEReplay *)findReplay:(NSString *)fileHash;
@end

@implementation ZEReplay
@dynamic replayPlayers, type, category, region, duration, map, fileHash, originalPath;

- (void)willTurnIntoFault {
    self.replayPlayers = nil;
    self.type = nil;
    self.category = nil;
    self.duration = nil;
    self.map = nil;
    self.region = nil;
    self.fileHash = nil;
    self.originalPath = nil;
    [super willTurnIntoFault];
}

- (id)initWithPath:(NSString *)path account:(NSString *)account {
    ZE_MPQ *mpq;
    ZE_RETVAL ret;
    CFStringRef account_id = NULL;
    CFStringRef region = NULL;
    CFDictionaryRef dict = NULL;
    CFStringRef hash = NULL;
    ZE_MPQ_ATTRIBUTE *attributes = NULL;
    uint32_t attributes_count = 0;
    
    if ((self = [super init])) {        
        self.originalPath = path;

        ret = ze_mpq_new_file(&mpq, (char *)[path UTF8String]);
        if (ret != ZE_SUCCESS) goto error;
        
        ret = ze_mpq_compute_hash(mpq, &hash);
        if (ret != ZE_SUCCESS) goto error;
        
        if ([self findReplay:(NSString *)hash] != nil) {
            goto error;
        }
        
        self.fileHash = (NSString *)hash;
        
        ret = ze_mpq_read_headers(mpq);
        if (ret != ZE_SUCCESS) goto error;

        ret = ze_mpq_read_initdata(mpq, &region, &account_id);
        if (ret != ZE_SUCCESS) goto error;
        
        self.region = (NSString *)region;
        
        ret = ze_mpq_read_attributes(mpq, &attributes, &attributes_count);
        if (ret != ZE_SUCCESS) goto error;
        
        uint32_t j;
        for (j = 0; j < attributes_count; j++) {
            ZE_MPQ_ATTRIBUTE *a = &attributes[j];
            if (a->player == 16) {
                switch (a->attribute_id) {
                    case ZE_ATTR_CATEGORY:
                        switch (a->value) {
                            case ZE_ATTR_PRIVATE:
                                self.category = @"Private";
                                break;
                            case ZE_ATTR_PUBLIC:
                                self.category = @"Public";
                                break;
                            case ZE_ATTR_LADDER:
                                self.category = @"Ladder";
                                break;
                        }
                        break;
                    case ZE_ATTR_GAME_TYPE:
                        switch (a->value) {
                            case ZE_ATTR_1V1:
                                self.type = @"1v1";
                                break;
                            case ZE_ATTR_2V2:
                                self.type = @"2v2";
                                break;
                            case ZE_ATTR_3V3:
                                self.type = @"3v3";
                                break;
                            case ZE_ATTR_4V4:
                                self.type = @"4v4";
                                break;
                            case ZE_ATTR_6V6:
                                self.type = @"6v6";
                                break;
                            case ZE_ATTR_FFA:
                                self.type = @"FFA";
                                break;
                            case ZE_ATTR_CUSTOM:
                                self.type = @"Custom";
                                break;
                        }
                        break;
                }
            }
        }
        
        ZE_STREAM *s;
        ret = ze_mpq_read_file(mpq, "replay.details", &s);
        if (ret != ZE_SUCCESS) goto error;
        

        ret = ze_stream_deserialize(s, (CFTypeRef *)&dict);
        if (ret != ZE_SUCCESS) goto error;

        NSString *mapName = [(NSDictionary *)dict objectForKey:[NSNumber numberWithInt:1]];
        ZEMap *m = [self findMap:mapName];
        m.name = mapName;
        self.map = m;
        
        NSUInteger i = 0;
        for (NSDictionary *player in [(NSDictionary *)dict objectForKey:[NSNumber numberWithInt:0]]) {
            NSString *name = [player objectForKey:[NSNumber numberWithInt:0]];
            NSNumber *bnetId = [[player objectForKey:[NSNumber numberWithInt:1]] 
                                objectForKey:[NSNumber numberWithInt:4]];
            NSNumber *outcome = [player objectForKey:[NSNumber numberWithInt:8]];
            
            NSString *race = NULL;
            NSNumber *team = [NSNumber numberWithInt:1];
            
            for (j = 0; j < attributes_count; j++) {
                ZE_MPQ_ATTRIBUTE *a = &attributes[j];
                if (a->player == i + 1) {
                    switch (a->attribute_id) {
                        case ZE_ATTR_PLAYER_RACE:
                            switch(a->value) {
                                case ZE_ATTR_TERRAN:
                                    race = @"Terran";
                                    break;
                                case ZE_ATTR_ZERG:
                                    race = @"Zerg";
                                    break;
                                case ZE_ATTR_PROTOSS:
                                    race = @"Protoss";
                                    break;
                                case ZE_ATTR_RANDOM:
                                    race = @"Random";
                                    break;
                            }
                            break;
                        case ZE_ATTR_TEAMS_1V1:
                            if ([self.type isEqualToString:@"1v1"]) {
                                
                                team = [NSNumber numberWithInt:((char *)&a->value)[0] - '0'];
                            }
                            break;
                        case ZE_ATTR_TEAMS_2V2:
                            if ([self.type isEqualToString:@"2v2"]) {
                                
                                team = [NSNumber numberWithInt:((char *)&a->value)[0] - '0'];
                            }
                            break;  
                        case ZE_ATTR_TEAMS_3V3:
                            if ([self.type isEqualToString:@"3v3"]) {
                                
                                team = [NSNumber numberWithInt:((char *)&a->value)[0] - '0'];
                            }
                            break;          
                        case ZE_ATTR_TEAMS_4V4:
                            if ([self.type isEqualToString:@"4v4"]) {
                                
                                team = [NSNumber numberWithInt:((char *)&a->value)[0] - '0'];
                            }
                            break;    
                        case ZE_ATTR_TEAMS_6V6:
                            if ([self.type isEqualToString:@"6v6"]) {
                                
                                team = [NSNumber numberWithInt:((char *)&a->value)[0] - '0'];
                            }
                            break;  
                    }
                }
            }
            
            ZEReplayPlayer *rp = [[[ZEReplayPlayer alloc] init] autorelease];
            rp.replay = self;
            rp.outcome = [outcome stringValue];
            rp.race = race;
            rp.won = [NSNumber numberWithBool:[outcome isEqualToNumber:[NSNumber numberWithInt:2]]];
            rp.team = team; // TODO
            
            ZEPlayer *p;
            p = [self findPlayerWithId:[bnetId stringValue] inRegion:(NSString *)region];
            p.name = name;
            p.bnetId = [bnetId stringValue];
            p.region = (NSString *)region;
            rp.player = p;
            
            [self.replayPlayers addObject:rp];
            
            i++;
        }
        
        
        CFRelease(dict);
        CFRelease(region);
        CFRelease(hash);
        CFRelease(account_id);
        free(attributes), attributes = NULL;
        ze_stream_close(s);
        ze_mpq_close(mpq);
    }
    
    return self;
    
error:
    [self.managedObjectContext deleteObject:self];

    free(attributes), attributes = NULL;
    
    if (hash != NULL) CFRelease(hash), hash = NULL;
    if (attributes != NULL) CFRelease(attributes), attributes = NULL;
    if (dict != NULL) CFRelease(dict), dict = NULL;
    if (account_id != NULL) CFRelease(account_id), account_id = NULL;
    if (region != NULL) CFRelease(region), region = NULL;
    ze_mpq_close(mpq);
    [self release];
    return nil;
}

- (ZEPlayer *)findPlayerWithId:(NSString *)bnetId inRegion:(NSString *)region {
    NSManagedObjectContext *moc = [ZEAppDelegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"ZEPlayer" inManagedObjectContext:moc];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"bnetId = %@ AND region = %@", bnetId, region];
    [request setPredicate:predicate];
    [request setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    if (array == nil || array.count == 0) {
        return [[[ZEPlayer alloc] init] autorelease];
    } else {
        return [array objectAtIndex:0];
    }
}

- (ZEMap *)findMap:(NSString *)name {
    NSManagedObjectContext *moc = [ZEAppDelegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"ZEMap" inManagedObjectContext:moc];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"name = %@", name];
    [request setPredicate:predicate];
    [request setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    if (array == nil || array.count == 0) {
        return [[[ZEMap alloc] init] autorelease];
    } else {
        return [array objectAtIndex:0];
    }
}

- (ZEReplay *)findReplay:(NSString *)fileHash {
    NSManagedObjectContext *moc = [ZEAppDelegate managedObjectContext];
    NSEntityDescription *entityDescription = [NSEntityDescription
                                              entityForName:@"ZEReplay" inManagedObjectContext:moc];
    NSFetchRequest *request = [[[NSFetchRequest alloc] init] autorelease];
    [request setEntity:entityDescription];
    
    NSPredicate *predicate = [NSPredicate predicateWithFormat:
                              @"fileHash = %@", fileHash];
    [request setPredicate:predicate];
    [request setFetchLimit:1];
    
    NSError *error = nil;
    NSArray *array = [moc executeFetchRequest:request error:&error];
    if (array == nil || array.count == 0) {
        return nil;
    } else {
        return [array objectAtIndex:0];
    }
}

@end
