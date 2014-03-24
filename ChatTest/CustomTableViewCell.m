//
//  CustomTableViewCell.m
//  ChatTest
//
//  Created by Jeremy Stone on 3/20/14.
//  Copyright (c) 2014 SolutionReach. All rights reserved.
//

#import "CustomTableViewCell.h"
#import "UIImage+ImageBubbles.h"
#import "TestTableViewController.h"


extern TestTableViewController* g_testTableController;


UIImage* ImageFromCacheWithURL(NSString* url)
{
  static NSMutableDictionary *storage = nil;
  
  if (!storage)
    storage = [NSMutableDictionary dictionary];
  
  UIImage *image = storage[url];
  if (!image && url.length)
  {
    image = [UIImage imageWithData:[NSData dataWithContentsOfURL:[NSURL URLWithString:url]]];
    if (image)
      storage[url] = image;
  }
  
  return image;
}


#define kMaxBubbleWidth               ([UIScreen mainScreen].applicationFrame.size.width * 0.7)   // 70%
#define kBubbleWidthOffset            ([UIScreen mainScreen].applicationFrame.size.width - kMaxBubbleWidth)
#define kSRLabelMarginForMessageCell  5.0

#define kStandardThumbnailSize        CGSizeMake([UIScreen mainScreen].applicationFrame.size.width * 0.45, [UIScreen mainScreen].applicationFrame.size.width * 0.45)
#define kIconThumbnailSize            CGSizeMake([UIScreen mainScreen].applicationFrame.size.width * 0.25, [UIScreen mainScreen].applicationFrame.size.width * 0.25)

@interface CustomTableViewCell ()

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *senderHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *timestampHeightConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *readReceiptheightConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubbleViewTrailingSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *bubbleViewLeadingSpaceConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskViewLeadingSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskViewTrailingSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *maskViewWidthConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewLeadingSpaceConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *textViewTrailingSpaceConstraint;

@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewWidthConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewLeadingConstraint;
@property (weak, nonatomic) IBOutlet NSLayoutConstraint *imageViewTrailingConstraint;

@property (assign, nonatomic) CGFloat timestampHeight;
@property (assign, nonatomic) CGFloat senderHeight;
@property (assign, nonatomic) CGFloat readReceiptHeight;
@property (assign, nonatomic) CGFloat textViewLeadingConstant;
@property (assign, nonatomic) CGFloat textViewTrailingConstant;
@property (assign, nonatomic) CGFloat maskViewLeadingConstant;
@property (assign, nonatomic) CGFloat maskViewTrailingConstant;
@property (assign, nonatomic) CGFloat bubbleViewLeadingConstant;
@property (assign, nonatomic) CGFloat bubbleViewTrailingConstant;

@end


@implementation CustomTableViewCell


- (void)awakeFromNib
{
  [super awakeFromNib];
  
  // remember base heights
  if (!self.timestampHeight)
    self.timestampHeight = self.timestamp.frame.size.height;
  if (!self.senderHeight)
    self.senderHeight = self.sender.frame.size.height;
  if (!self.readReceiptHeight)
    self.readReceiptHeight = self.readReceipt.frame.size.height;
  
  // remember base left offsets
  
  self.textViewLeadingConstant = self.textViewLeadingSpaceConstraint.constant;
  self.textViewTrailingConstant = self.textViewTrailingSpaceConstraint.constant;
  self.maskViewLeadingConstant = self.maskViewLeadingSpaceConstraint.constant;
  self.maskViewTrailingConstant = self.maskViewTrailingSpaceConstraint.constant;
  self.bubbleViewLeadingConstant = self.bubbleViewLeadingSpaceConstraint.constant;
  self.bubbleViewTrailingConstant = self.bubbleViewTrailingSpaceConstraint.constant;
}


+ (CGFloat)heightForCellWithData:(NSDictionary *)message nextRowData:(NSDictionary *)nextMessage
{
  CGFloat labelHeight = 21.0;
  CGFloat retVal = 0;
  
  NSString *str = message[@"timestamp"];
  if (str.length)
    retVal += labelHeight;
  
  str = message[@"sender"];
  if (str.length)
    retVal += labelHeight;
  
  // figure out text height
  str = message[@"message"];
  if (message[@"url"])        // images override text
    str = nil;
  
  if (str.length)
  {
    CGSize size = [CustomTableViewCell textSizeForMessage:message withFont:[UIFont systemFontOfSize:14]];
    retVal += size.height;
    
    // add the non-stretchable parts of the background bubble here as well.
    retVal += labelHeight;

    // check to see if no read receipt here and a sender or timestamp is on the next row and get rid of the read receipt margin
    if (![message[@"readreceipt"] length] && ([nextMessage[@"sender"] length] || [nextMessage[@"timestamp"] length]))
      retVal -= labelHeight;
  }
  else
  {
    // image height.
    retVal += kStandardThumbnailSize.height;
#warning    // if this is an icon, return the image icon size instead of the actual image
  }
  
  return retVal;
}


+ (CGSize)textSizeForMessage:(NSDictionary *)message withFont:(UIFont *)font
{
  CGFloat maxWidth = kMaxBubbleWidth;
  
  if (!font)
    return CGSizeZero;
  
  NSString* str = message[@"message"];
  
  CGRect stringRect = [str boundingRectWithSize:CGSizeMake(maxWidth, 99999)
                                        options:NSStringDrawingUsesLineFragmentOrigin
                                     attributes:@{ NSFontAttributeName : font }
                                        context:nil];
  
  stringRect.size.height += 15;   // for UITextView top and bottom text margins
  
  return CGRectIntegral(stringRect).size;
}


#pragma mark -


- (void)shiftCell:(BOOL)toRight
{
  if (toRight)
  {
    // adjust bubble view
    if (self.bubbleViewTrailingSpaceConstraint.constant > self.bubbleViewLeadingSpaceConstraint.constant)
    {
      CGFloat tempValue = self.bubbleViewLeadingSpaceConstraint.constant;
      self.bubbleViewLeadingSpaceConstraint.constant = self.bubbleViewTrailingSpaceConstraint.constant;
      self.bubbleViewTrailingSpaceConstraint.constant = tempValue;
    }
    
    // adjust mask view
    if (self.maskViewTrailingSpaceConstraint.constant > self.maskViewLeadingSpaceConstraint.constant)
    {
      CGFloat tempValue = self.maskViewLeadingSpaceConstraint.constant;
      self.maskViewLeadingSpaceConstraint.constant = self.maskViewTrailingSpaceConstraint.constant;
      self.maskViewTrailingSpaceConstraint.constant = tempValue;
    }
    
    // adjust text view
    if (self.textViewTrailingSpaceConstraint.constant > self.textViewLeadingSpaceConstraint.constant)
    {
      CGFloat tempValue = self.textViewLeadingSpaceConstraint.constant;
      self.textViewLeadingSpaceConstraint.constant = self.textViewTrailingSpaceConstraint.constant;
      self.textViewTrailingSpaceConstraint.constant = tempValue;
    }
    
    // adjust the labels
    self.sender.textAlignment = NSTextAlignmentRight;
    self.readReceipt.textAlignment = NSTextAlignmentRight;
  }
  else
  {
    // bubble view
    if (self.bubbleViewTrailingSpaceConstraint.constant < self.bubbleViewLeadingSpaceConstraint.constant)
    {
      CGFloat tempValue = self.bubbleViewLeadingSpaceConstraint.constant;
      self.bubbleViewLeadingSpaceConstraint.constant = self.bubbleViewTrailingSpaceConstraint.constant;
      self.bubbleViewTrailingSpaceConstraint.constant = tempValue;
    }
    
    // mask view
    if (self.maskViewTrailingSpaceConstraint.constant < self.maskViewLeadingSpaceConstraint.constant)
    {
      CGFloat tempValue = self.maskViewLeadingSpaceConstraint.constant;
      self.maskViewLeadingSpaceConstraint.constant = self.maskViewTrailingSpaceConstraint.constant;
      self.maskViewTrailingSpaceConstraint.constant = tempValue;
    }
    
    // adjust text view
    if (self.textViewTrailingSpaceConstraint.constant < self.textViewLeadingSpaceConstraint.constant)
    {
      CGFloat tempValue = self.textViewLeadingSpaceConstraint.constant;
      self.textViewLeadingSpaceConstraint.constant = self.textViewTrailingSpaceConstraint.constant;
      self.textViewTrailingSpaceConstraint.constant = tempValue;
    }
    
    // adjust the labels
    self.sender.textAlignment = NSTextAlignmentLeft;
    self.readReceipt.textAlignment = NSTextAlignmentLeft;
  }
}


- (void)updateWidthConstraints:(BOOL)toRight
{
  if (!self.maskImage.hidden)
  {
    /* tricksy.  We set a constraint holding the image and image mask to the left AND the
     right.  To choose which we want we change the priority of the constraints.  An 
     alternate method would be to remove the proper constraint and re-create the one
     we want.  I hear this is expensive, though if that's any different than changing
     the priority I don't know.
     */
    
    self.imageViewWidthConstraint.constant = kStandardThumbnailSize.width;
    self.maskViewWidthConstraint.constant = kStandardThumbnailSize.width;
    
    // image adjustments
    if (toRight)
    {
      // shifted right
      self.maskViewLeadingSpaceConstraint.priority = UILayoutPriorityFittingSizeLevel;
      self.imageViewLeadingConstraint.priority = UILayoutPriorityFittingSizeLevel;
      
      self.maskViewTrailingSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
      self.imageViewTrailingConstraint.priority = UILayoutPriorityDefaultHigh;
    }
    else
    {
      // shifted left
      self.maskViewLeadingSpaceConstraint.priority = UILayoutPriorityDefaultHigh;
      self.imageViewLeadingConstraint.priority = UILayoutPriorityDefaultHigh;
      
      self.maskViewTrailingSpaceConstraint.priority = UILayoutPriorityFittingSizeLevel;
      self.imageViewTrailingConstraint.priority = UILayoutPriorityFittingSizeLevel;
    }
  }
  else
  {
    // text adjustments
  }
}


- (void)loadWithData:(NSDictionary *)message nextMessageData:(NSDictionary *)nextMessage
{
  self.textView.text = message[@"message"];
  self.sender.text = message[@"sender"];
  self.timestamp.text = message[@"timestamp"];
  self.readReceipt.text = message[@"readreceipt"];
  
  BOOL messageFromMe = [message[@"sender"] isEqualToString:@"me"];
  
  NSString* url = message[@"url"];
  if (url.length)
  {
    // handle image laoding here
    self.textView.text = nil;
    self.bubbleView.hidden = YES;

    self.urlImageView.image = ImageFromCacheWithURL(url);
    self.urlImageView.hidden = NO;
    
    self.maskImage.image = [self maskImageForType:messageFromMe];
    self.maskImage.hidden = NO;
  }
  else
  {
    self.bubbleView.hidden = NO;
    self.urlImageView.hidden = YES;
    self.urlImageView.image = nil;
    self.maskImage.hidden = YES;
    self.maskImage.image = nil;

    // handle background bubble
    self.bubbleView.image = [self bubbleImageForColor:[UIColor grayColor] type:messageFromMe];  // YES is left
  }
  
  // update data-based constraints
  // sender
  if (!self.sender.text.length)
    self.senderHeightConstraint.constant = 0;
  else
    self.senderHeightConstraint.constant = self.senderHeight;

  // timestamp
  if (!self.timestamp.text.length)
    self.timestampHeightConstraint.constant = 0;
  else
    self.timestampHeightConstraint.constant = self.timestampHeight;

  // read receipt
  if (!self.readReceipt.text.length)
  {
    if ([nextMessage[@"timestamp"] length] || [nextMessage[@"sender"] length])
      self.readReceiptheightConstraint.constant = 0;
  }
  else
  {
    self.readReceiptheightConstraint.constant = self.readReceiptHeight;
  }
  
  // update constraints based on left/right
  [self shiftCell:messageFromMe];
  
  // update constraints for non-standard widths (short text or images)
  [self updateWidthConstraints:messageFromMe];
    
  // until we make changes this is meaningless
  [self setNeedsUpdateConstraints];
}


#pragma mark -


- (UIImage *)imageBackgroundMask
{
  UIImage *image = [UIImage imageNamed:@"ImageBubbleMask"];
  return [image stretchableImageWithLeftCapWidth:image.size.width / 2.0 topCapHeight:image.size.height / 2.0];
}


- (UIImage *)maskImageForType:(BOOL)left
{
  UIImage *normalBubble = [self imageBackgroundMask];
  
  if (left == YES)
    normalBubble = [normalBubble js_imageFlippedHorizontal];
  
  // make image stretchable from center point
  CGPoint center = CGPointMake(normalBubble.size.width / 2.0f, normalBubble.size.height / 2.0f);
  UIEdgeInsets capInsets = UIEdgeInsetsMake(center.y, center.x, center.y, center.x);
  
  return [normalBubble resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
}


- (UIImage *)bubbleImageForColor:(UIColor *)color type:(BOOL)left
{
  UIImage *bubble = [UIImage imageNamed:@"ImageBubble"];
  UIImage *normalBubble = [bubble js_imageMaskWithColor:color];
  
  if (left == YES)
    normalBubble = [normalBubble js_imageFlippedHorizontal];
  
  // make image stretchable from center point
  CGPoint center = CGPointMake(bubble.size.width / 2.0f, bubble.size.height / 2.0f);
  UIEdgeInsets capInsets = UIEdgeInsetsMake(center.y, center.x, center.y, center.x);
  
  return [normalBubble resizableImageWithCapInsets:capInsets resizingMode:UIImageResizingModeStretch];
}


@end
