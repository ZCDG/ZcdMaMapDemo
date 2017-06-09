//
//  SelectAroundTableViewCell.m
//  ParkingSpaceSpirit
//
//  Created by 张张文龙 on 2017/5/17.
//  Copyright © 2017年 zhangwenlong. All rights reserved.
//

#import "SelectAroundTableViewCell.h"
#import "UIColor+ColorWithHexString.h"
#define ScreenWidth [UIScreen mainScreen].bounds.size.width
#define ScreenHeight [UIScreen mainScreen].bounds.size.height
@implementation SelectAroundTableViewCell

 
- (instancetype)initWithStyle:(UITableViewCellStyle)style reuseIdentifier:(NSString *)reuseIdentifier {
    if (self = [super initWithStyle:style reuseIdentifier:reuseIdentifier]) {
        self.contentView.backgroundColor = [UIColor whiteColor];
        [self makeUI];
    }
    return self;
}
- (void)makeUI {
    CGFloat spaceX = 15.0f ,spaceY = 5.0f;
    //上边
    UILabel *topLabel = [[UILabel alloc]initWithFrame:CGRectMake(2 * spaceX, spaceY, ScreenWidth - 60, 20)];
    topLabel.font = [UIFont systemFontOfSize:14.0f];
    //topLabel.backgroundColor = [UIColor greenColor];
    topLabel.textColor = [UIColor blackColor];
    [self.contentView addSubview:topLabel];
    self.topLabel = topLabel;
    UIImageView *iconImageV = [[UIImageView alloc]initWithFrame:CGRectMake(15, 18.5f, 8, 13)];
    iconImageV.image = [UIImage imageNamed:@"location"];
    //iconImageV.backgroundColor = [UIColor redColor];
    [self.contentView addSubview:iconImageV];
    
    //下边
    UILabel *contentLabel = [[UILabel alloc]initWithFrame:CGRectMake(2 * spaceX, spaceY + 20, ScreenWidth - 70, 20)];
    //contentLabel.backgroundColor = [UIColor redColor];
    contentLabel.font = [UIFont systemFontOfSize:12.0f];
    contentLabel.textAlignment = NSTextAlignmentLeft;
    contentLabel.textColor = [UIColor colorWithHexString:@"8C8C8C"];
    [self.contentView addSubview:contentLabel];
    self.contentLabel = contentLabel;
   
    
}



- (void)awakeFromNib {
    [super awakeFromNib];
    // Initialization code
}

- (void)setSelected:(BOOL)selected animated:(BOOL)animated {
    [super setSelected:selected animated:animated];

    // Configure the view for the selected state
}

@end
