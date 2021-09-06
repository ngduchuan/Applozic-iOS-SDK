//
//  ALLogger.h
//
//  Created by Matt Coneybeare on 09/1/13.
//  Copyright (c) 2013 Urban Apps, LLC. All rights reserved.
//

#import <Foundation/Foundation.h>

/// `ALLoggerVerbosity` levels for showing  none, basic, plain or full logs.
typedef enum {
    ALLoggerVerbosityNone = 0,
    ALLoggerVerbosityPlain,
    ALLoggerVerbosityBasic,
    ALLoggerVerbosityFull
} ALLoggerVerbosity;

/// `ALLoggerSeverity` log levels for showing in Xcode log console.
typedef enum {
    /// Unset means it is not factored in on the decision to log, defaulting to the production vs debug and user overrides.
    ALLoggerSeverityUnset = 0,
    /// Lowest log level.
    ALLoggerSeverityDebug,
    ALLoggerSeverityInfo,
    ALLoggerSeverityWarn,
    ALLoggerSeverityError,
    /// Highest log level.
    ALLoggerSeverityFatal
} ALLoggerSeverity;


#define ALSLogFull( s, f, ... )	[ALLogger logWithVerbosity:ALLoggerVerbosityFull\
												  severity:s\
												formatArgs:@[\
															self,\
															[[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
															[NSNumber numberWithInt:__LINE__],\
															NSStringFromSelector(_cmd),\
															[NSString stringWithFormat:(f), ##__VA_ARGS__]\
															]\
								]

#define ALSLogBasic( s, f, ... ) [ALLogger logWithVerbosity:ALLoggerVerbosityBasic\
												   severity:s\
												 formatArgs:@[\
															 [[NSString stringWithUTF8String:__FILE__] lastPathComponent],\
															 [NSNumber numberWithInt:__LINE__],\
															 [NSString stringWithFormat:(f), ##__VA_ARGS__]\
															 ]\
								 ]

#define ALSLogPlain( s, f, ... ) [ALLogger logWithVerbosity:ALLoggerVerbosityPlain\
												   severity:s\
												 formatArgs:@[\
															 [NSString stringWithFormat:(f), ##__VA_ARGS__]\
															]\
								 ]

#define ALLogFull( format, ... )			ALSLogFull( ALLoggerSeverityUnset, format, ##__VA_ARGS__ )
#define ALLogBasic( format, ... )			ALSLogBasic( ALLoggerSeverityUnset, format, ##__VA_ARGS__ )
#define ALLogPlain( format, ... )			ALSLogPlain( ALLoggerSeverityUnset, format, ##__VA_ARGS__ )

#define ALLog( format, ... )				ALLogBasic( format, ##__VA_ARGS__ )
#define ALSLog( severity, format, ... )		ALSLogBasic( severity, format, ##__VA_ARGS__ )

#ifdef ALLogGER_SWIZZLE_NSLOG
#define NSLog( s, ... )		ALLog( s, ##__VA_ARGS__ )
#endif

/// This is just convenience
#define NSStringFromBool(b) (b ? @"YES" : @"NO")

/// This is the default NSUserDefaults key
static NSString *const ALLogger_LoggingEnabled = @"ALLogger_LoggingEnabled";

/// `ALLogger` is used for logging logs of Applozic
@interface ALLogger : NSObject
/// Returns the format string for the verbosity. See [+ initialize] for defaults
+ (NSString *)formatForVerbosity:(ALLoggerVerbosity)verbosity;
/// Overrides the default formats for verbosities.
+ (void)setFormat:(NSString *)format
     forVerbosity:(ALLoggerVerbosity)verbosity;
/// Resets the formats back to ALLogger defaults.
+ (void)resetDefaultLogFormats;
/// Set the Minimum for showing logs.
+ (void)setMinimumSeverity:(ALLoggerSeverity)severity;
/// Defaults to ALLoggerSeverityUnset (not used in determining whether or not to log).
+ (ALLoggerSeverity)minimumSeverity;
/// Yes if minimumSeverity has been set.
+ (BOOL)usingSeverityFiltering;
/// Yes if severity is greater than or equal to minimumSeverity
+ (BOOL)meetsMinimumSeverity:(ALLoggerSeverity)severity;
/// Returns YES when DEBUG is not present in the Preprocessor Macros
+ (BOOL)isProduction;
/// Default is NO.
+ (BOOL)shouldLogInProduction;
/// Default is YES.
+ (BOOL)shouldLogInDebug;
/// Default is NO. Cached BOOL of the userDefaultsKey.
+ (BOOL)userDefaultsOverride;
/// :nodoc:
+ (void)setShouldLogInProduction:(BOOL)shouldLogInProduction;
/// :nodoc:
+ (void)setShouldLogInDebug:(BOOL)shouldLogInDebug;
/// :nodoc:
+ (void)setUserDefaultsOverride:(BOOL)userDefaultsOverride;
/// returns true if (not production and shouldLogInDebug) OR (production build and shouldLogInProduction) or (userDefaultsOverride == YES)
+ (BOOL)loggingEnabled;
/// Default key is ALLogger_LoggingEnabled
+ (NSString *)userDefaultsKey;
/// :nodoc:
+ (void)setUserDefaultsKey:(NSString *)userDefaultsKey;

/// Logs a format, and variables for the format.
+ (void)log:(NSString *)format, ...;

/// Logs a preset format based on the vspecified verbosity, and variables for the format.
+ (void)logWithVerbosity:(ALLoggerVerbosity)verbosity
                severity:(ALLoggerSeverity)severity
              formatArgs:(NSArray *)args;

/// gets singleton instance of logArray - from disk, or new
+ (NSMutableArray *)logArray;
/// use inside applicationWillTerminate: for continuous logging
+ (void)saveLogArray;
/// :nodoc:
+ (NSString *)logArrayFilepath;
/// convenience method / migration from -applicationLog
+ (NSString *)logArrayAsString;

@end
