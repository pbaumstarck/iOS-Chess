//
//  ChessViewController.h
//  Chess
//
//  Created by Paul Baumstarck on 12/9/11.
//

#import <UIKit/UIKit.h>
#define SQUARE_SIZE 33

#define SizeofBoardState 66

typedef struct BoardState {
	// The characters of the board
	char board[64];

	// _En passant_ handling:
	// - The index of the last move if it was an _en passant_-able
	int enPassantableIx;

	// Castling handling, with flags indicate whether anything has moved:
	// - Black is bits 0 through 3 (0xf):
	// -- Bit 0 - King
	// -- Bit 1 - 'a' file rook
	// -- Bit 2 - 'h' file rook
	// - White is bits 4 through 7 (0xf0):
	// -- Bit 4 - King
	// -- Bit 5 - 'a' file rook
	// -- Bit 6 - 'h' file rook
	unsigned char castlingMoves;
} BoardState;

typedef enum DisplayState {
	DisplayingGame,
	DisplayingPromotionScreen,
	DisplayingLoadScreen,
} DisplayState;

@interface ChessViewController : UIViewController {
	// The origin of the board, which actually shouldn't be needed
	CGPoint boardOrigin;

	// Movement bool
	bool whitesMove;
	// The number of moves that have occurred
	int nMoves;
	// The capacity of the 'history' array
	int historyCapacity;
	// The number of cached, redo-able moves
	int nCachedMoves;
	// The state of the display
	DisplayState displayState;

	// What state we are in:
	// 0 - Waiting for a click
	// 1 - Have selected a piece, displaying valid moves
	int selectionState;
	// The piece that was most recently selected for movement
	int lastSelectedPiece;
	// The bitmap of cached valid/highlighted moves
	unsigned long long lastValidityBitmap;

	// The state of the board, with 64 spaces arranged row-contiguously. Character identifies the piece:
	// ' ' - None
	// p - Pawn
	// r - Rook
	// n - Knight
	// b - Bishop
	// q - Queen
	// k - King
	// Lowercase letters indicate black, uppercase indicate white.
	//char *state;
	BoardState state;
	// The history of the game
	//char **history;
	BoardState *history;

	// Promotion members
	int promotionIx;

	// The piece images
	UIImage *whitePawn;
	UIImage *whiteRook;
	UIImage *whiteKnight;
	UIImage *whiteBishop;
	UIImage *whiteQueen;
	UIImage *whiteKing;
	UIImage *blackPawn;
	UIImage *blackRook;
	UIImage *blackKnight;
	UIImage *blackBishop;
	UIImage *blackQueen;
	UIImage *blackKing;
}

@property (nonatomic, retain) UILabel *moveLabel;
// The squares that display images
@property (nonatomic, retain) NSMutableArray *squares;
// The transparent buttons that trigger events and have borders
@property (nonatomic, retain) NSMutableArray *buttons;
// Property version of the 'Undo' button
@property (nonatomic, retain) UIButton *undoButton;
// Property version of the 'Redo' button
@property (nonatomic, retain) UIButton *redoButton;

// Images that display captured white pieces
@property (nonatomic, retain) NSMutableArray *capturedWhites;
// Images that display captured black pieces
@property (nonatomic, retain) NSMutableArray *capturedBlacks;

// The action for when a square is touched
-(IBAction)squareClicked:(id)sender;
//- (void)handleTap:(UITapGestureRecognizer *)recognizer;
//-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event;
// Whether the 'Undo' button was clicked
-(IBAction)btnUndoClicked:(id)sender;
// Whether the 'Redo' button was clicked
-(IBAction)btnRedoClicked:(id)sender;
// When a promotion button was clicked
-(IBAction)btnPromotionClicked:(id)sender;


- (int) numberOfColumnsInPickerView:(UIPickerView*)picker;
- (int) pickerView:(UIPickerView*)picker numberOfRowsInColumn:(int)col;
//- (UIPickerTableCell*) pickerView:(UIPickerView*)picker tableCellForRow:(int)row inColumn:(int)col;
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component;

@end

