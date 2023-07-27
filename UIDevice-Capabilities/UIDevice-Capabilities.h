
@interface UIDevice (Capabilities)
- (BOOL) supportsCapability: (NSString *) capability;
- (id) fetchCapability: (NSString *) capability;
- (NSArray *) capabilityArray;
- (void) scanCapabilities;
@end
