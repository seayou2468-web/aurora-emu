#import "../Views/AURBackgroundView.h"
#import "AURLibraryViewController.h"
#import "AURSettingsViewController.h"
#import "AUREmulatorViewController.h"
#import "../Views/AURGameCollectionViewCell.h"
#import "../Managers/AURDatabaseManager.h"
#import "../Managers/AURBoxArtManager.h"
#import "../Models/AURGame.h"
#import <UniformTypeIdentifiers/UniformTypeIdentifiers.h>

@interface AURLibraryViewController () <UICollectionViewDelegate, UICollectionViewDataSource, UIDocumentPickerDelegate>
@property (nonatomic, strong) UICollectionView *collectionView;
@property (nonatomic, strong) UISegmentedControl *segmentedControl;
@property (nonatomic, strong) NSArray<AURGame *> *games;
@property (nonatomic, strong) AURBackgroundView *backgroundView;
@end

@implementation AURLibraryViewController

static NSString * const kAURROMDirectory = @"ROMs";

- (void)viewDidLoad {
    [super viewDidLoad];
    self.view.backgroundColor = [UIColor blackColor];

    // Background Aurora View
    self.backgroundView = [[AURBackgroundView alloc] initWithFrame:self.view.bounds];
    [self.view addSubview:self.backgroundView];
    self.backgroundView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.backgroundView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.backgroundView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.backgroundView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.backgroundView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];

    // Glassmorphic Navigation Bar appearance
    UINavigationBarAppearance *appearance = [[UINavigationBarAppearance alloc] init];
    [appearance configureWithTransparentBackground];
    appearance.backgroundEffect = [UIBlurEffect effectWithStyle:UIBlurEffectStyleDark];
    appearance.titleTextAttributes = @{NSForegroundColorAttributeName: [UIColor whiteColor], NSFontAttributeName: [UIFont systemFontOfSize:22 weight:UIFontWeightBold]};
    self.navigationItem.standardAppearance = appearance;
    self.navigationItem.scrollEdgeAppearance = appearance;
    self.title = @"Aurora";

    // ... (rest of the setup)

    // Setup Segmented Control for Systems (Glassmorphic)
    self.segmentedControl = [[UISegmentedControl alloc] initWithItems:@[@"GBA", @"GBC", @"GB", @"NES", @"NDS", @"3DS"]];
    self.segmentedControl.selectedSegmentIndex = 0;
    [self.segmentedControl addTarget:self action:@selector(segmentChanged:) forControlEvents:UIControlEventValueChanged];
    self.navigationItem.titleView = self.segmentedControl;

    // Appearance
    self.segmentedControl.selectedSegmentTintColor = [UIColor colorWithWhite:1.0 alpha:0.2];
    [self.segmentedControl setTitleTextAttributes:@{NSForegroundColorAttributeName: [UIColor whiteColor]} forState:UIControlStateNormal];

    // Settings Button (Modern)
    self.navigationItem.leftBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"line.3.horizontal.circle.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(settingsTapped)];
    self.navigationItem.leftBarButtonItem.tintColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.76 alpha:1.0]; // Aurora Cyan

    // Add Button
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithImage:[UIImage systemImageNamed:@"plus.circle.fill"] style:UIBarButtonItemStylePlain target:self action:@selector(addTapped)];
    self.navigationItem.rightBarButtonItem.tintColor = [UIColor colorWithRed:0.0 green:1.0 blue:0.76 alpha:1.0];

    // Setup Collection View (Compositional Layout)
    UICollectionViewCompositionalLayout *layout = [self _createLayout];
    self.collectionView = [[UICollectionView alloc] initWithFrame:self.view.bounds collectionViewLayout:layout];
    self.collectionView.delegate = self;
    self.collectionView.dataSource = self;
    self.collectionView.backgroundColor = [UIColor clearColor];
    [self.collectionView registerClass:[AURGameCollectionViewCell class] forCellWithReuseIdentifier:@"GameCell"];
    [self.view addSubview:self.collectionView];

    self.collectionView.translatesAutoresizingMaskIntoConstraints = NO;
    [NSLayoutConstraint activateConstraints:@[
        [self.collectionView.topAnchor constraintEqualToAnchor:self.view.topAnchor],
        [self.collectionView.bottomAnchor constraintEqualToAnchor:self.view.bottomAnchor],
        [self.collectionView.leadingAnchor constraintEqualToAnchor:self.view.leadingAnchor],
        [self.collectionView.trailingAnchor constraintEqualToAnchor:self.view.trailingAnchor]
    ]];

    [self reloadData];
}

- (void)viewWillAppear:(BOOL)animated {
    [super viewWillAppear:animated];
    [self reloadData];
}

- (UICollectionViewCompositionalLayout *)_createLayout {
    return [[UICollectionViewCompositionalLayout alloc] initWithSectionProvider:^NSCollectionLayoutSection * _Nullable(NSInteger sectionIndex, id<NSCollectionLayoutEnvironment>  _Nonnull layoutEnvironment) {
        NSCollectionLayoutSize *itemSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:0.33] heightDimension:[NSCollectionLayoutDimension fractionalHeightDimension:1.0]];
        NSCollectionLayoutItem *item = [NSCollectionLayoutItem itemWithLayoutSize:itemSize];
        item.contentInsets = NSDirectionalEdgeInsetsMake(8, 8, 8, 8);

        NSCollectionLayoutSize *groupSize = [NSCollectionLayoutSize sizeWithWidthDimension:[NSCollectionLayoutDimension fractionalWidthDimension:1.0] heightDimension:[NSCollectionLayoutDimension fractionalWidthDimension:0.5]];
        NSCollectionLayoutGroup *group = [NSCollectionLayoutGroup horizontalGroupWithLayoutSize:groupSize subitems:@[item]];

        NSCollectionLayoutSection *section = [NSCollectionLayoutSection sectionWithGroup:group];
        section.contentInsets = NSDirectionalEdgeInsetsMake(16, 8, 16, 8);
        return section;
    }];
}

- (void)segmentChanged:(UISegmentedControl *)sender {
    [self reloadData];
}

- (void)reloadData {
    EmulatorCoreType type;
    switch (self.segmentedControl.selectedSegmentIndex) {
        case 0: type = EMULATOR_CORE_TYPE_GBA; break;
        case 1: type = EMULATOR_CORE_TYPE_GB; break;
        case 2: type = EMULATOR_CORE_TYPE_GB; break; // Actually GB
        case 3: type = EMULATOR_CORE_TYPE_NES; break;
        case 4: type = EMULATOR_CORE_TYPE_NDS; break;
        case 5: type = EMULATOR_CORE_TYPE_3DS; break;
        default: type = EMULATOR_CORE_TYPE_GBA; break;
    }
    self.games = [[AURDatabaseManager sharedManager] gamesForCoreType:type];
    [self.collectionView reloadData];
}

- (void)settingsTapped {
    AURSettingsViewController *settingsVC = [[AURSettingsViewController alloc] init];
    UINavigationController *nav = [[UINavigationController alloc] initWithRootViewController:settingsVC];
    [self presentViewController:nav animated:YES completion:nil];
}

- (void)addTapped {
    NSArray<UTType *> *types = @[
        UTTypeData,
        [UTType typeWithFilenameExtension:@"gba"] ?: UTTypeData,
        [UTType typeWithFilenameExtension:@"gb"] ?: UTTypeData,
        [UTType typeWithFilenameExtension:@"gbc"] ?: UTTypeData,
        [UTType typeWithFilenameExtension:@"nes"] ?: UTTypeData,
        [UTType typeWithFilenameExtension:@"nds"] ?: UTTypeData,
        [UTType typeWithFilenameExtension:@"3ds"] ?: UTTypeData,
        [UTType typeWithFilenameExtension:@"cci"] ?: UTTypeData,
        [UTType typeWithFilenameExtension:@"cxi"] ?: UTTypeData,
        [UTType typeWithFilenameExtension:@"cia"] ?: UTTypeData
    ];
    UIDocumentPickerViewController *picker = [[UIDocumentPickerViewController alloc] initForOpeningContentTypes:types asCopy:NO];
    picker.delegate = self;
    [self presentViewController:picker animated:YES completion:nil];
}

#pragma mark - UIDocumentPickerDelegate

- (void)documentPicker:(UIDocumentPickerViewController *)controller didPickDocumentsAtURLs:(NSArray<NSURL *> *)urls {
    NSURL *url = urls.firstObject;
    if (!url) return;

    NSString *ext = [[url.pathExtension lowercaseString] stringByTrimmingCharactersInSet:NSCharacterSet.whitespaceAndNewlineCharacterSet];
    EmulatorCoreType coreType = [self coreTypeForExtension:ext];
    if (coreType == -1) {
        [self presentSimpleAlertWithTitle:@"Unsupported ROM" message:@"対応拡張子: gba/gb/gbc/nes/nds/3ds/cci/cxi/cia"];
        return;
    }

    NSString *importedPath = [self importROMAtURL:url];
    if (importedPath.length == 0) {
        [self presentSimpleAlertWithTitle:@"Import Failed" message:@"ROMの取り込みに失敗しました。"];
        return;
    }

    AURGame *game = [[AURGame alloc] init];
    game.title = [[url lastPathComponent] stringByDeletingPathExtension];
    game.romPath = importedPath;
    game.coreType = coreType;

    [[AURDatabaseManager sharedManager] addGame:game];
    [self reloadData];
}

#pragma mark - UICollectionViewDelegate

- (UIContextMenuConfiguration *)collectionView:(UICollectionView *)collectionView contextMenuConfigurationForItemAtIndexPath:(NSIndexPath *)indexPath point:(CGPoint)point {
    AURGame *game = self.games[indexPath.item];
    return [UIContextMenuConfiguration configurationWithIdentifier:nil previewProvider:nil actionProvider:^UIMenu * _Nullable(NSArray<UIMenuElement *> * _Nonnull suggestedActions) {
        UIAction *play = [UIAction actionWithTitle:@"Play" image:[UIImage systemImageNamed:@"play.fill"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [self collectionView:collectionView didSelectItemAtIndexPath:indexPath];
        }];
        UIAction *rename = [UIAction actionWithTitle:@"Rename" image:[UIImage systemImageNamed:@"pencil"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {}];
        UIAction *delete = [UIAction actionWithTitle:@"Delete" image:[UIImage systemImageNamed:@"trash"] identifier:nil handler:^(__kindof UIAction * _Nonnull action) {
            [[AURDatabaseManager sharedManager] removeGame:game removeROMFile:YES];
            [self reloadData];
        }];
        delete.attributes = UIMenuElementAttributesDestructive;

        return [UIMenu menuWithTitle:game.title children:@[play, rename, delete]];
    }];
}

- (void)collectionView:(UICollectionView *)collectionView didSelectItemAtIndexPath:(NSIndexPath *)indexPath {
    if (self.presentedViewController != nil) {
        return;
    }

    AURGame *game = self.games[indexPath.item];
    if (![[NSFileManager defaultManager] fileExistsAtPath:game.romPath]) {
        [[AURDatabaseManager sharedManager] removeGame:game removeROMFile:NO];
        [self reloadData];
        return;
    }

    NSURL *romURL = [NSURL fileURLWithPath:game.romPath];
    AUREmulatorViewController *emuVC = [[AUREmulatorViewController alloc] initWithROMURL:romURL coreType:game.coreType];
    emuVC.modalPresentationStyle = UIModalPresentationFullScreen;
    [self presentViewController:emuVC animated:YES completion:nil];
}

#pragma mark - UICollectionViewDataSource

- (NSInteger)collectionView:(UICollectionView *)collectionView numberOfItemsInSection:(NSInteger)section {
    return self.games.count;
}

- (UICollectionViewCell *)collectionView:(UICollectionView *)collectionView cellForItemAtIndexPath:(NSIndexPath *)indexPath {
    AURGameCollectionViewCell *cell = [collectionView dequeueReusableCellWithReuseIdentifier:@"GameCell" forIndexPath:indexPath];
    AURGame *game = self.games[indexPath.item];
    cell.titleLabel.text = game.title;

    cell.imageView.image = nil;
    [[AURBoxArtManager sharedManager] fetchBoxArtForGameTitle:game.title completion:^(UIImage *image) {
        if (image) {
            cell.imageView.image = image;
        } else {
            // Fallback image or color
            cell.imageView.backgroundColor = [UIColor colorWithWhite:0.2 alpha:1.0];
        }
    }];

    return cell;
}

- (NSString *)documentsDirectory {
    return NSSearchPathForDirectoriesInDomains(NSDocumentDirectory, NSUserDomainMask, YES).firstObject;
}

- (NSString *)romsDirectory {
    NSString *dir = [[self documentsDirectory] stringByAppendingPathComponent:kAURROMDirectory];
    [[NSFileManager defaultManager] createDirectoryAtPath:dir withIntermediateDirectories:YES attributes:nil error:nil];
    return dir;
}

- (EmulatorCoreType)coreTypeForExtension:(NSString *)ext {
    if ([ext isEqualToString:@"gba"]) return EMULATOR_CORE_TYPE_GBA;
    if ([ext isEqualToString:@"nes"]) return EMULATOR_CORE_TYPE_NES;
    if ([ext isEqualToString:@"nds"]) return EMULATOR_CORE_TYPE_NDS;
    if ([ext isEqualToString:@"3ds"] || [ext isEqualToString:@"cci"] || [ext isEqualToString:@"cxi"] || [ext isEqualToString:@"cia"]) return EMULATOR_CORE_TYPE_3DS;
    if ([ext isEqualToString:@"gb"] || [ext isEqualToString:@"gbc"]) return EMULATOR_CORE_TYPE_GB;
    return (EmulatorCoreType)-1;
}

- (NSString *)importROMAtURL:(NSURL *)url {
    if (!url.isFileURL) return nil;

    BOOL accessed = [url startAccessingSecurityScopedResource];
    NSString *fileName = url.lastPathComponent ?: @"imported.rom";
    NSString *destinationPath = [[self romsDirectory] stringByAppendingPathComponent:fileName];

    NSFileManager *fm = NSFileManager.defaultManager;
    if ([fm fileExistsAtPath:destinationPath]) {
        NSString *basename = [fileName stringByDeletingPathExtension];
        NSString *ext = [fileName pathExtension];
        NSString *uniqueName = (ext.length > 0)
            ? [NSString stringWithFormat:@"%@-%@.%@", basename, NSUUID.UUID.UUIDString, ext]
            : [NSString stringWithFormat:@"%@-%@", basename, NSUUID.UUID.UUIDString];
        destinationPath = [[self romsDirectory] stringByAppendingPathComponent:uniqueName];
    }

    NSError *copyError = nil;
    [fm copyItemAtURL:url toURL:[NSURL fileURLWithPath:destinationPath] error:&copyError];

    if (accessed) {
        [url stopAccessingSecurityScopedResource];
    }
    if (copyError) {
        NSLog(@"[AUR][Library] ROM import failed: %@", copyError.localizedDescription);
        return nil;
    }
    return destinationPath;
}

- (void)presentSimpleAlertWithTitle:(NSString *)title message:(NSString *)message {
    UIAlertController *alert = [UIAlertController alertControllerWithTitle:title
                                                                   message:message
                                                            preferredStyle:UIAlertControllerStyleAlert];
    [alert addAction:[UIAlertAction actionWithTitle:@"OK" style:UIAlertActionStyleDefault handler:nil]];
    [self presentViewController:alert animated:YES completion:nil];
}

@end
