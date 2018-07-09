//
//  FILDSStore.m
//  Filie
//
//  Created by Uli Kusterer on 09.07.18.
//  Copyright © 2018 Uli Kusterer. All rights reserved.
//

#import "FILDSStore.h"


@interface FILDSStore ()

@property NSData *data;
@property NSMutableArray<NSNumber *> *offsets;
@end

@implementation FILDSStore

-(instancetype) initWithURL: (NSURL *)inURL
{
	if (self = [super init])
	{
		NSInteger offset = 0;
		_data = [NSData dataWithContentsOfURL: inURL];
		if (_data)
		{
			uint32_t version = [self readUInt32At: &offset];
			NSAssert(version == 1, @"Unsupported DS_Store version.");
			uint32_t magicCode = [self readUInt32At: &offset];
			NSAssert(magicCode == 0x42756431, @"Magic code in DS_Store file is not 'Bud1'.");
			uint32_t rootBlockOffset1 = [self readUInt32At: &offset];
			uint32_t rootBlockSize = [self readUInt32At: &offset];
			uint32_t rootBlockOffset2 = [self readUInt32At: &offset];
			
			NSAssert(rootBlockOffset1 == rootBlockOffset2, @"Damaged DS_Store file.");
			
			offset += 16; // Unknown bytes.
			
			// Root block:
			offset = 4 + rootBlockOffset1;
			
			_offsets = [NSMutableArray new];
			
			uint32_t offsetCount = [self readUInt32At: &offset];
			uint32_t zeroFill = [self readUInt32At: &offset];
			NSAssert(zeroFill == 0, @"Warning, zero filler has a value.");
			for (uint32_t x = 0; x < offsetCount; ++x)
			{
				[_offsets addObject: @([self readUInt32At: &offset])];
			}
			
			uint32_t fullBlocksWeHad = offsetCount / 256;
			uint32_t usedIntsInLastBlock = offsetCount - (fullBlocksWeHad * 256);
			if (usedIntsInLastBlock != 0)
			{
				offset += (256 - usedIntsInLastBlock) * 4;
			}
			
			// TOC:
			NSMutableDictionary<NSString *, NSNumber *> *tocs = [NSMutableDictionary new];
			
			uint32_t tocCount = [self readUInt32At: &offset];
			for (uint32_t x = 0; x < tocCount; ++x)
			{
				NSString *tocName = [self readUTF8StringAt: &offset];
				NSNumber *tocValue = @([self readUInt8At: &offset]);
				[tocs setObject: tocValue forKey: tocName];
			}
			
			// Free list:
//			NSMutableDictionary<NSNumber *, NSArray *> *frees = [NSMutableDictionary new];
//			for (uint32_t x = 0; x < 32; ++x)
//			{
//				NSMutableArray<NSNumber *> *bucket = [NSMutableArray new];
//				uint32_t numOffsetsInBucket = [self readUInt32At: &offset];
//				for (uint32_t y = 0; y < numOffsetsInBucket; ++y)
//				{
//					NSNumber *bucketEntry = @([self readUInt32At: &offset]);
//					[bucket addObject: bucketEntry];
//				}
//				[frees setObject: bucket forKey: @(1 << x)];
//			}
			
			// Tree:
			uint32_t startBlockID = tocs[@"DSDB"].integerValue;
			uint32_t firstOffsetSize = (uint32_t) _offsets[startBlockID].integerValue;
			offset = (firstOffsetSize & ~31) + 4; // Mask out size info and add the usual 4 to get offset.
			uint32_t firstSize = 1 << (firstOffsetSize & 31);	// 2 ^ <5 low bits> == size.

			uint32_t firstBlockID = [self readUInt32At: &offset];
			uint32_t levelsOfInternalBlocks = [self readUInt32At: &offset];
			uint32_t numRecordsInTree = [self readUInt32At: &offset];
			uint32_t numBlocksInTree = [self readUInt32At: &offset];
			uint32_t magicNumber = [self readUInt32At: &offset];
			NSAssert(magicNumber == 0x100c, @"Magic number has unexpected value");
			
			[self readBlockWithID: firstBlockID];
		}
	}
	return self;
}


-(void)	readBlockWithID: (uint32_t)inBlockID
{
	uint32_t firstOffsetSize = (uint32_t) _offsets[inBlockID -1].integerValue;
	
	NSInteger offset = (firstOffsetSize & ~31) + 4; // Mask out size info and add the usual 4 to get offset.
	uint32_t firstSize = 1 << (firstOffsetSize & 31);	// 2 ^ <5 low bits> == size.
	
	uint32_t blockType = [self readUInt32At: &offset];
	uint32_t numEntries = [self readUInt32At: &offset];
	if (blockType == 0)
	{
		for (int x = 0; x < numEntries; ++x)
		{
			[self readOneRecordAt: &offset];
		}
	}
	else
	{
		NSLog(@"blockType = %u", blockType);
		
		for (int x = 0; x < numEntries; ++x)
		{
			uint32_t nextBlockID = [self readUInt32At: &offset];
			NSLog(@"nextBlockID = %u", nextBlockID);
			
			[self readOneRecordAt: &offset];

			[self readBlockWithID: nextBlockID];
		}
	}

}


-(void) readOneRecordAt: (NSInteger *)inOffset
{
	NSString *fileName = [self readUTF16StringAt: inOffset];
	NSString *propertyName = [self readFourCCStringAt: inOffset];
	uint32_t dataType = [self readUInt32At: inOffset];
	
	NSString * propertyValue = @"<error>";
	
	switch (dataType)
	{
		case 'long':
		{
			int32_t theNum = [self readInt32At: inOffset];
			propertyValue = [NSString stringWithFormat: @"%d", theNum];
			break;
		}
		case 'shor':
		{
			*inOffset += 2; // Skip padding.
			int16_t theNum = [self readInt16At: inOffset];
			propertyValue = [NSString stringWithFormat: @"%d", theNum];
			break;
		}
		case 'bool':
		{
			uint8_t theBool = [self readUInt8At: inOffset];
			propertyValue = (theBool == 0) ? @"NO" : @"YES";
			break;
		}
		case 'blob':
		{
			NSData *data = [self readDataAt: inOffset];
			propertyValue = data.description;
			break;
		}
		case 'type':
			propertyValue = [self readFourCCStringAt: inOffset];
			break;
		case 'ustr':
			propertyValue = [self readUTF16StringAt: inOffset];
			break;
		case 'comp':
			*inOffset += 8;
			propertyValue = @"[complex number]";
			break;
		case 'dutc': // UTC timestamp since Jan 1st 1904.
		{
			uint64_t dateStamp = [self readUInt64At: inOffset];
			NSTimeInterval since1904interval = ((double)dateStamp) / (1.0/65536);
			NSDate *jan1904 = [NSDate dateWithTimeIntervalSinceReferenceDate: -3061152000.000000];
			NSDate *actualDate = [NSDate dateWithTimeInterval: since1904interval sinceDate: jan1904];
			propertyValue = actualDate.description;
			break;
		}
	}
	
	NSLog(@"%@: %@=%@", fileName, propertyName, propertyValue);
}


-(uint64_t) readUInt64At: (NSInteger *)inOffset
{
	uint64_t *currInt = (uint64_t *) (((uint8_t*)_data.bytes) + (*inOffset));
	*inOffset += sizeof(uint64_t);
	return NSSwapBigLongLongToHost(*currInt);
}


-(uint32_t) readUInt32At: (NSInteger *)inOffset
{
	uint32_t *currInt = (uint32_t *) (((uint8_t*)_data.bytes) + (*inOffset));
	*inOffset += sizeof(uint32_t);
	return NSSwapBigIntToHost(*currInt);
}


-(uint16_t) readUInt16At: (NSInteger *)inOffset
{
	uint16_t *currInt = (uint16_t *) (((uint8_t*)_data.bytes) + (*inOffset));
	*inOffset += sizeof(uint16_t);
	return NSSwapBigShortToHost(*currInt);
}


-(uint8_t) readUInt8At: (NSInteger *)inOffset
{
	uint8_t *currInt = ((uint8_t*)_data.bytes) + (*inOffset);
	*inOffset += sizeof(uint8_t);
	return *currInt;
}


-(int32_t) readInt32At: (NSInteger *)inOffset
{
	int32_t *currInt = (int32_t *) (((int8_t*)_data.bytes) + (*inOffset));
	*inOffset += sizeof(int32_t);
	return NSSwapBigIntToHost(*currInt);
}


-(int16_t) readInt16At: (NSInteger *)inOffset
{
	int16_t *currInt = (int16_t *) (((int8_t*)_data.bytes) + (*inOffset));
	*inOffset += sizeof(int16_t);
	return NSSwapBigShortToHost(*currInt);
}


-(int8_t) readInt8At: (NSInteger *)inOffset
{
	int8_t *currInt = ((int8_t*)_data.bytes) + (*inOffset);
	*inOffset += sizeof(int8_t);
	return *currInt;
}


-(NSString *) readUTF16StringAt: (NSInteger *)inOffset
{
	uint32_t charCount = [self readUInt32At: inOffset];
	unichar *currBytes = (unichar *) (((uint8_t*)_data.bytes) + (*inOffset));
	
	NSString *result = [[NSString alloc] initWithBytes: currBytes length: charCount * sizeof(unichar) encoding: NSUTF16BigEndianStringEncoding];
	*inOffset += charCount * 2;
	return result;
}


-(NSString *) readUTF8StringAt: (NSInteger *)inOffset
{
	uint8_t charCount = [self readUInt8At: inOffset];
	char *currBytes = (((char*)_data.bytes) + (*inOffset));
	
	NSString *result = [[NSString alloc] initWithBytes: currBytes length: charCount encoding: NSUTF8StringEncoding];
	*inOffset += charCount;
	return result;
}

-(NSString *) readFourCCStringAt: (NSInteger *)inOffset
{
	uint8_t charCount = 4;
	char *currBytes = (((char*)_data.bytes) + (*inOffset));
	
	NSString *result = [[NSString alloc] initWithBytes: currBytes length: charCount encoding: NSMacOSRomanStringEncoding];
	*inOffset += charCount;
	return result;
}


-(NSData *)	readDataAt:(NSInteger *)inOffset
{
	uint32_t charCount = [self readUInt32At: inOffset];
	unichar *currBytes = (unichar *) (((uint8_t*)_data.bytes) + (*inOffset));
	
	NSData *result = [[NSData alloc] initWithBytes: currBytes length: charCount];
	*inOffset += charCount;
	return result;
}

@end
