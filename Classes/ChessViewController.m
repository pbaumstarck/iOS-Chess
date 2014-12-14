//
//  ChessViewController.m
//  Chess
//
//  Created by Paul Baumstarck on 12/9/11.
//

#import <QuartzCore/QuartzCore.h>
#import "ChessViewController.h"

@interface  ChessViewController()
// Updates the images to display the contents of 'state'
-(void)updateBoard;
// Whether there is a piece at the given index
-(bool)isPieceAt:(int)ix;
// Whether there is a piece at the given index
-(bool)isPieceAtRow:(int)row andColumn:(int)column;
// If the piece at the given index is white (undefined if no piece is present)
-(bool)isWhitePieceAt:(int)ix;
// If the piece at the given index is white (false means black or no piece)
-(bool)isWhitePieceAtRow:(int)row andColumn:(int)column;

// Highlight the position at '(row, column)'
-(void)highlightRow:(int)row andColumn:(int)column inMap:(unsigned long long*)bitmap;
// Highlight the position at '(row, column)' knowing that it is a capture
-(void)highlightRow:(int)row andColumn:(int)column inMap:(unsigned long long*)bitmap isCapture:(bool)isCapture;

// Highlight the valid moves for a rook
-(int)highlightRookMovesFromRow:(int)r andColumn:(int)c inMap:(unsigned long long*)bitmap;
// Highlight the valid moves for a bishop
-(int)highlightBishopMovesFromRow:(int)r andColumn:(int)c inMap:(unsigned long long*)bitmap;
// Highlight the valid moves for the piece at 'ix', and return the number of valid moves
-(int)highlightValidMovesFrom:(int)ix inMap:(unsigned long long*)bitmap;

// Checks whether a given square is attackable by white or black
-(bool)isCheckedRow:(int)row andColumn:(int)column byWhite:(bool)byWhite;

// Add a possible captured piece to the display of materiel
-(void)tallyCaptured:(char)piece;
// Save board state
-(void)saveBoardState;
// Promote a black or white pawn
-(void)promotePawnAt:(int)ix isWhite:(bool)isWhite;

// Get the appropriate castling bits for the current player
-(unsigned char)getCastlingBits;
// Set the appropriate castling bits for the current player
-(void)setCastlingBits:(unsigned char)bits;
// Execute a move to the given square from the last selected square
-(void)executeMove:(int)ix fromLastSelected:(int)lastSelected;

// Disply the picker for loading a game
-(void)displayLoadGamePicker;

@end

@implementation ChessViewController

@synthesize squares = _squares,
moveLabel = _moveLabel,
buttons = _buttons,
undoButton = _undoButton,
redoButton = _redoButton,
capturedWhites = _capturedWhites,
capturedBlacks = _capturedBlacks;

/*
// The designated initializer. Override to perform setup that is required before the view is loaded.
- (id)initWithNibName:(NSString *)nibNameOrNil bundle:(NSBundle *)nibBundleOrNil {
    if ((self = [super initWithNibName:nibNameOrNil bundle:nibBundleOrNil])) {
        // Custom initialization
		self.squares = [[NSMutableArray alloc] initWithCapacity:64];
		// Create the labels
    }
    return self;
}*/

// Implement loadView to create a view hierarchy programmatically, without using a nib.
- (void)loadView {
	self.view = [[UIView alloc] initWithFrame:CGRectMake(0, 0, 320, 480)];
	self.view.backgroundColor = [UIColor grayColor];

	// Set up the 'Undo' button
	self.undoButton = [[UIButton alloc] initWithFrame:CGRectMake(20, 430, 130, 37)];
	[self.undoButton setBackgroundColor:[UIColor whiteColor]];
	[self.undoButton setTitle:@"Undo" forState:UIControlStateNormal];
	[self.undoButton setTitleColor:[[UIColor alloc] initWithRed:50.0/255.0 green:79.0/255.0 blue:133.0/255.0 alpha:1.0]
						  forState:UIControlStateNormal];
	self.undoButton.layer.cornerRadius = 8;
	self.undoButton.layer.borderWidth = 1;
	self.undoButton.layer.borderColor = self.undoButton.titleLabel.textColor.CGColor;
	[self.undoButton addTarget:self action:@selector(btnUndoClicked:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:self.undoButton];

	// Set up the 'Redo' button
	self.redoButton = [[UIButton alloc] initWithFrame:CGRectMake(170, 430, 130, 37)];
	[self.redoButton setBackgroundColor:[UIColor whiteColor]];
	[self.redoButton setTitle:@"Redo" forState:UIControlStateNormal];
	[self.redoButton setTitleColor:[[UIColor alloc] initWithRed:50.0/255.0 green:79.0/255.0 blue:133.0/255.0 alpha:1.0]
						  forState:UIControlStateNormal];
	self.redoButton.layer.cornerRadius = 8;
	self.redoButton.layer.borderWidth = 1;
	self.redoButton.layer.borderColor = self.redoButton.titleLabel.textColor.CGColor;
	[self.redoButton addTarget:self action:@selector(btnRedoClicked:) forControlEvents:UIControlEventTouchUpInside];
	[self.view addSubview:self.redoButton];


	// Allocate the captured pieces arrays
	self.capturedWhites = [[NSMutableArray alloc] initWithCapacity:16];
	self.capturedBlacks = [[NSMutableArray alloc] initWithCapacity:16];

	// Load our images
	self->whitePawn = [UIImage imageNamed:@"WhitePawn.png"];
	self->whiteRook = [UIImage imageNamed:@"WhiteRook.png"];
	self->whiteKnight = [UIImage imageNamed:@"WhiteKnight.png"];
	self->whiteBishop = [UIImage imageNamed:@"WhiteBishop.png"];
	self->whiteQueen = [UIImage imageNamed:@"WhiteQueen.png"];
	self->whiteKing = [UIImage imageNamed:@"WhiteKing.png"];
	self->blackPawn = [UIImage imageNamed:@"BlackPawn.png"];
	self->blackRook = [UIImage imageNamed:@"BlackRook.png"];
	self->blackKnight = [UIImage imageNamed:@"BlackKnight.png"];
	self->blackBishop = [UIImage imageNamed:@"BlackBishop.png"];
	self->blackQueen = [UIImage imageNamed:@"BlackQueen.png"];
	self->blackKing = [UIImage imageNamed:@"BlackKing.png"];

	// Find the board's origin
	int originX = (320 - SQUARE_SIZE * 8) >> 1;
	int originY = 70;//(480 - SQUARE_SIZE * 8) >> 1;
	self->boardOrigin = CGPointMake(originX, originY);


	// Initialize the internal state
	self->nMoves = 0;
	self->whitesMove = true;
	self->selectionState = 0;
	self->lastSelectedPiece = -1;
	self->promotionIx = -1;
	self->nCachedMoves = 0;
	self->displayState = DisplayingGame;

	// Create the 'move' label and say it's white's move
	self.moveLabel = [[UILabel alloc] initWithFrame:CGRectMake(0, originY - 54, 320, 40)];
	self.moveLabel.textColor = [UIColor whiteColor];
	self.moveLabel.text = @"Move: White";
	[self.moveLabel setFont:[UIFont fontWithName:@"Helvetica-Bold" size:22]];
	self.moveLabel.textAlignment = UITextAlignmentCenter;
	[self.moveLabel setBackgroundColor:[[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]];
	[self.view addSubview:self.moveLabel];

	// Add all the labels to view
	self.squares = [[NSMutableArray alloc] initWithCapacity:64];
	self.buttons = [[NSMutableArray alloc] initWithCapacity:64];
    UIColor *darkSquare = [[UIColor alloc] initWithRed:202.0/255.0 green:134.0/255.0 blue:68.0/255.0 alpha:1.0];
	UIColor *lightSquare = [[UIColor alloc] initWithRed:255.0/255.0 green:206.0/255.0 blue:158.0/255.0 alpha:1.0];
	for (int r = 0; r < 8; ++r) {
		for (int c = 0; c < 8; ++c) {
			CGRect rect = CGRectMake(self->boardOrigin.x + c * SQUARE_SIZE,
									 self->boardOrigin.y + r * SQUARE_SIZE,
									 SQUARE_SIZE,
									 SQUARE_SIZE);
			UIImageView *square = [[UIImageView alloc] initWithFrame:rect];
			[square setBackgroundColor:(c % 2 != (r % 2) ? darkSquare : lightSquare)];
			square.image = nil;
			[self.squares addObject:square];
			[self.view addSubview:square];

			// Add a transparent button over it to accept events
			UIButton *button = [[UIButton alloc] initWithFrame:rect];
			[button setBackgroundColor:[[UIColor alloc] initWithRed:0.0 green:0.0 blue:0.0 alpha:0.0]];
			[button addTarget:self action:@selector(squareClicked:) forControlEvents:UIControlEventTouchUpInside];
			//[button setTitle:@" " forState:UIControlStateNormal];
			button.layer.cornerRadius = 8;
			button.layer.borderWidth = 3;
			//button.layer.borderColor = [UIColor grayColor].CGColor;
			button.layer.borderColor = [UIColor clearColor].CGColor;
			button.clipsToBounds = YES;
			[self.buttons addObject:button];
			[self.view addSubview:button];

			bool above = false;
			if ((above = r == 0) || r == 7) {
				// Draw letters above
				UILabel *letter = [[UILabel alloc] initWithFrame:CGRectMake(rect.origin.x,
																			rect.origin.y + (above ? -28 : 25),
																			rect.size.width,
																			rect.size.height)];
				letter.text = [[NSString alloc] initWithFormat:@"%c", (char)((int)'a' + c)];
				letter.font = [UIFont fontWithName:@"Helvetica" size:12];
				letter.backgroundColor = [UIColor clearColor];
				letter.textAlignment = UITextAlignmentCenter;
				[self.view addSubview:letter];
			}
			bool left = false;
			if ((left = c == 0) || c == 7) {
				// Draw letters to the sides
				UILabel *letter = [[UILabel alloc] initWithFrame:CGRectMake(rect.origin.x + (left ? -28 : 28),
																			rect.origin.y,
																			rect.size.width,
																			rect.size.height)];
				letter.text = [[NSString alloc] initWithFormat:@"%d", (8 - r)];
				letter.font = [UIFont fontWithName:@"Helvetica" size:12];
				letter.backgroundColor = [UIColor clearColor];
				letter.textAlignment = UITextAlignmentCenter;
				[self.view addSubview:letter];
			}

		}
	}

	// Initialize the state of the board
	//self->state = (char*)malloc(sizeof(char) * 64);
	memset(self->state.board, ' ', sizeof(char) * 64);
	self->state.enPassantableIx = -1;
	// The appropriate flags get initialized to 1 to say that they haven't been moved
	self->state.castlingMoves = 0x77u;
	// Pawns
	for (int c = 0; c < 8; ++c) {
		self->state.board[8 + c] = 'p';
		self->state.board[48 + c] = 'P';
	}
	// Rooks
	self->state.board[0] = 'r';
	self->state.board[7] = 'r';
	self->state.board[56] = 'R';
	self->state.board[63] = 'R';
	// Knights
	self->state.board[1] = 'n';
	self->state.board[6] = 'n';
	self->state.board[57] = 'N';
	self->state.board[62] = 'N';
	// Bishops
	self->state.board[2] = 'b';
	self->state.board[5] = 'b';
	self->state.board[58] = 'B';
	self->state.board[61] = 'B';
	// Queens
	self->state.board[3] = 'q';
	self->state.board[59] = 'Q';
	// Kings
	self->state.board[4] = 'k';
	self->state.board[60] = 'K';

	// To test promotion
	if (false) {
		self->state.board[0] = ' ';
		self->state.board[8] = 'P';
		self->state.board[63] = ' ';
		self->state.board[55] = 'p';
	}
	// To test castling
	if (false) {
		// Get rid of the bishops, knights, and queens
		self->state.board[1] = ' ';
		self->state.board[6] = ' ';
		self->state.board[57] = ' ';
		self->state.board[62] = ' ';
		self->state.board[2] = ' ';
		self->state.board[5] = ' ';
		self->state.board[58] = ' ';
		self->state.board[61] = ' ';
		self->state.board[3] = ' ';
		self->state.board[59] = ' ';
	}
	// To test _en passant_
	if (false) {
		self->state.board[3 * 8 + 5] = 'P';
		self->state.board[4 * 8 + 5] = 'p';
	}

	[self updateBoard];

	// Allocate the history space and save the current state
	self->history = (BoardState*)malloc(sizeof(BoardState) * (self->historyCapacity = 16));
	memcpy(&self->history[0], &self->state, sizeof(BoardState));

	//[self displayLoadGamePicker];
}

-(void)displayLoadGamePicker {
	// Create a big semi-transparent panel to put everything on
	UIView *bigPanelView = [[[UIView alloc] initWithFrame:CGRectMake(00, 40, 320, 400)] autorelease];
	[bigPanelView setBackgroundColor:[[UIColor alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:0.8]];
	bigPanelView.layer.cornerRadius = 8;
	bigPanelView.layer.borderWidth = 2;
	bigPanelView.layer.borderColor = self.undoButton.titleLabel.textColor.CGColor;
	//CGRect rect = CGRectMake(20, 10, 140, 30);

	UIPickerView *picker = [[UIPickerView alloc] initWithFrame:CGRectMake(0, 20, 320, 320)];
	picker.delegate = self;
	picker.showsSelectionIndicator = YES;
	[bigPanelView addSubview:picker];
	//[self.view addSubview:picker];
	[self.view addSubview:bigPanelView];

	// Add just add some buttons and actually gave something on file for parsing chess games, yeah ...
	self->displayState = DisplayingLoadScreen;
}
- (int) numberOfColumnsInPickerView:(UIPickerView*)picker {
	return 1;
}
- (int) pickerView:(UIPickerView*)picker numberOfRowsInColumn:(int)col {
	return col == 0 ? 2 : 0;
}
//- (UIPickerTableCell*) pickerView:(UIPickerView*)picker tableCellForRow:(int)row inColumn:(int)col;
- (NSString*)pickerView:(UIPickerView *)pickerView titleForRow:(NSInteger)row forComponent:(NSInteger)component {
	if (component != 0) {
		return nil;
	}
	switch (row) {
		case 0:
			return @"The Immortal Game";
		case 1:
			return @"The Game of the Century";
		default:
			return nil;
	}
}


// Whether there is a piece at the given index
-(bool)isPieceAt:(int)ix {
	return ix >= 0 && ix < 64 && self->state.board[ix] != ' ';
}
// Whether there is a piece at the given index
-(bool)isPieceAtRow:(int)row andColumn:(int)column {
	return row >= 0 && row < 8 && column >= 0 && column < 8 && self->state.board[row * 8 + column] != ' ';
}
// If the piece at the given index is white (false means black or no piece)
-(bool)isWhitePieceAt:(int)ix {
	if (ix >= 0 && ix < 64) {
		char c = self->state.board[ix];
		return c >= 'A' && c <= 'Z';
	} else {
		return false;
	}
}
// If the piece at the given index is white (false means black or no piece)
-(bool)isWhitePieceAtRow:(int)row andColumn:(int)column {
	if (row >= 0 && row < 8 && column >= 0 && column < 8) {
		char c = self->state.board[row * 8 + column];
		return c >= 'A' && c <= 'Z';
	} else {
		return false;
	}
}

-(void)clearHighlighting {
	// De-highlight all valid moves
	for (UIButton *button in self.buttons) {
		//[button setBackgroundColor:[UIColor clearColor]];
		button.layer.borderColor = [UIColor clearColor].CGColor;
	}
}

// The action for when a square is pressed
-(IBAction)squareClicked:(id)sender {
	if (self->displayState != DisplayingGame) {
		return;
	}
	int ix = 0;
	// Figure out which thing we are
	for (id square in self.buttons) {
		if (square == sender) {
			break;
		}
		++ix;
	}
	if (ix >= 64) {
		// Bad
	}
	switch (self->selectionState) {
		case 0:
			// They have selected this piece to move
			if (![self isPieceAt:ix]) {
				// No piece there, dummy
				return;
			}
			if (self->whitesMove ^ [self isWhitePieceAt:ix]) {
				// Didn't select the right kind of piece
				return;
			}
			// Highlight the valid moves
			self->lastSelectedPiece = ix;
			int nValids = [self highlightValidMovesFrom:ix inMap:(unsigned long long*)&self->lastValidityBitmap];
			if (nValids > 0) {
				// Set that we've picked this piece and have moved to the next thing
				self->selectionState = 1;
			} else {
				// Forget about the selection
				self->lastSelectedPiece = -1;
			}
			break;
		case 1:
		{
			// We're trying to move the piece from 'lastSelectedPiece' to 'ix'
			unsigned long long validity = self->lastValidityBitmap;
			int lastSelected = self->lastSelectedPiece;
			// Clear the highlighting and other state now
			[self clearHighlighting];
			self->lastSelectedPiece = -1;
			self->selectionState = 0;
			self->lastValidityBitmap = 0x0uLL;

			if ((validity & (0x1uLL << ix)) != 0) {
				[self executeMove:ix fromLastSelected:lastSelected];
			}
		}
			break;
	}
}

// Get the appropriate castling bits for the current player
-(unsigned char)getCastlingBits {
	return self->whitesMove ? (self->state.castlingMoves &0x70u) >> 4 : (self->state.castlingMoves & 0x7u);
}
// Set the appropriate castling bits for the current player
-(void)setCastlingBits:(unsigned char)bits {
	unsigned char prevBits = self->state.castlingMoves;
	if (self->whitesMove) {
		prevBits = (prevBits & 0xfu) | (bits << 4);
	} else {
		prevBits = (prevBits & 0xf0u) | bits;
	}
	self->state.castlingMoves = prevBits;
}

// Execute a move to the given square from the last selected square
-(void)executeMove:(int)ix fromLastSelected:(int)lastSelected {
	// First save the game state in the history stack
	if (self->nMoves >= self->historyCapacity) {
		self->history = (BoardState*)realloc(self->history, SizeofBoardState * (self->historyCapacity <<= 1));
	}
	memcpy(&self->history[self->nMoves], &self->state, sizeof(BoardState));

	// Capture the identity of the piece we're moving
	char piece = self->state.board[lastSelected];
	char agnosticPiece = piece >= 'A' && piece <= 'Z' ? (piece - ('A' - 'a')) : piece;
	// Get the row and column of the piece we're moving
	int oldR = lastSelected >> 3, oldC = lastSelected & 0x7;
	// Get the row and column that we're moving it to
	int newR = ix >> 3, newC = ix & 0x7;

	// Check if we're doing an _en passant_ capture
	if (self->state.enPassantableIx != -1) {
		int enR = self->state.enPassantableIx >> 3, enC = self->state.enPassantableIx & 0x7;
		int newR = ix >> 3, newC = ix & 0x7;
		if (enC == newC && (piece == 'p' || piece == 'P')) {
			int forward = self->whitesMove ? -1 : 1;
			if (enR == newR - forward) {
				// Delete the captured pawn
				self->state.board[self->state.enPassantableIx] = ' ';
			}
		}
	}

	// Check if we made an _en passant_-able pawn move
	if (piece == 'p' || piece == 'P') {
		if (oldR - newR == 2 || oldR - newR == -2) {
			self->state.enPassantableIx = ix;
		} else {
			self->state.enPassantableIx = -1;
		}
	} else {
		self->state.enPassantableIx = -1;
	}

	unsigned char castlingBits = [self getCastlingBits];

	// Check if we are doing a castling move
	if (agnosticPiece == 'k' /*&& (castlingBits & 0x1u) != 0*/) {
		// So castling was still possible, and we moved a king
		if (newC == oldC + 2) {
			// King-side castling, so move the 'h' file rook, too
			self->state.board[oldR * 8 + (oldC + 3)] = ' ';
			self->state.board[oldR * 8 + (oldC + 1)] = self->whitesMove ? 'R' : 'r';
		} else if (newC == oldC - 2) {
			// Queen-side castling, so move the 'a' file rook, too
			self->state.board[oldR * 8 + (oldC - 4)] = ' ';
			self->state.board[oldR * 8 + (oldC - 1)] = self->whitesMove ? 'R' : 'r';
		}
	}
	// Update the castling bits accordingly
	if (agnosticPiece == 'k' || agnosticPiece == 'r') {
		// We moved a king or a rook, so update the state of the castling bits
		switch (agnosticPiece) {
			case 'k':
				// We're moving the king
				if ((castlingBits & 0x1u) != 0) {
					// And we haven't yet, so clear the bit
					castlingBits &= ~0x1u;
				}
				break;
			case 'r':
				// We're moving a rook ...
				if (oldC == 0) {
					// ... on the 'a' file
					if ((castlingBits & 0x2u) != 0) {
						// And we haven't yet, so clear the bit
						castlingBits &= ~0x2u;
					}
				} else if (oldC == 7) {
					// ... on the 'h' file
					if ((castlingBits & 0x4u) != 0) {
						// And we haven't yet, so clear the bit
						castlingBits &= ~0x4u;
					}
				}
				break;
		}
		// Update the castling bits
		[self setCastlingBits:castlingBits];
	}

	// Advance the state of the board
	++self->nMoves;
	self->nCachedMoves = self->nMoves;
	char captured = self->state.board[ix];
	[self tallyCaptured:captured];
	self->state.board[ix] = piece;
	self->state.board[lastSelected] = ' ';
	self->whitesMove ^= true;
	[self updateBoard];

	// Check if we have to do a promotion
	int r = ix >> 3;
	if (piece == 'P' && r == 0) {
		// White pawn gets promoted
		[self promotePawnAt:ix isWhite:true];
	} else if (piece == 'p' && r == 7) {
		// Black pawn gets promoted
		[self promotePawnAt:ix isWhite:false];
	}

	[self saveBoardState];
}

// Save the current state of the board
-(void)saveBoardState {
	// And save the current state of the board right away
	memcpy(&self->history[self->nMoves], &self->state, sizeof(BoardState));
}

// Promote a pawn that is black or white
-(void)promotePawnAt:(int)ix isWhite:(bool)isWhite {
	self->promotionIx = ix;
	self->displayState = DisplayingPromotionScreen;
	UIView *bigPanelView = [[[UIView alloc] initWithFrame:CGRectMake(70, 120, 180, 200)] autorelease];
	[bigPanelView setBackgroundColor:[[UIColor alloc] initWithRed:1.0 green:1.0 blue:1.0 alpha:0.8]];
	bigPanelView.layer.cornerRadius = 8;
	bigPanelView.layer.borderWidth = 2;
	bigPanelView.layer.borderColor = self.undoButton.titleLabel.textColor.CGColor;
	CGRect rect = CGRectMake(20, 10, 140, 30);

	// Add a label
	UILabel *label;
	label = [[UILabel alloc] initWithFrame:rect];
	label.text = @"Promote to:";
	label.textColor = [UIColor blackColor];
	label.textAlignment = UITextAlignmentCenter;
	label.backgroundColor = [UIColor clearColor];
	[bigPanelView addSubview:label];
	rect.origin.y += 34;

	NSString *strings[4] = { @"Queen", @"Knight", @"Rook", @"Bishop" };
	// Add buttons for the pieces
	UIButton *button;
	for (int i = 0; i < 4; ++i) {
		button = [[UIButton alloc] initWithFrame:rect];
		[button setTitle:strings[i] forState:UIControlStateNormal];
		[button setTitleColor:[UIColor blackColor] forState:UIControlStateNormal];
		button.layer.cornerRadius = 8;
		button.layer.borderWidth = 1;
		button.layer.borderColor = self.undoButton.titleLabel.textColor.CGColor;
		[bigPanelView addSubview:button];
		rect.origin.y += 34;
		[button addTarget:self action:@selector(btnPromotionClicked:) forControlEvents:UIControlEventTouchUpInside];
	}

	[self.view addSubview:bigPanelView];
	bigPanelView.alpha = 0.0;

	[UIView beginAnimations:@"fadein" context:nil];
	[UIView setAnimationDuration:0.5f];
	[UIView setAnimationCurve:UIViewAnimationCurveEaseInOut];
	[UIView setAnimationDelegate:self];
	// Change any animatable properties here
	bigPanelView.alpha = 1.0;
	[UIView commitAnimations];
}

// When a promotion button was clicked
-(IBAction)btnPromotionClicked:(id)sender {
	UIButton *button = (UIButton*)sender;
	if ([button.titleLabel.text isEqualToString:@"Queen"]) {
		self->state.board[self->promotionIx] = self->whitesMove ? 'q' : 'Q';
	} else if ([button.titleLabel.text isEqualToString:@"Knight"]) {
		self->state.board[self->promotionIx] = self->whitesMove ? 'n' : 'N';
	} else if ([button.titleLabel.text isEqualToString:@"Rook"]) {
		self->state.board[self->promotionIx] = self->whitesMove ? 'r' : 'R';
	} else {
		self->state.board[self->promotionIx] = self->whitesMove ? 'b' : 'B';
	}
	// Save the board state
	[self saveBoardState];
	[self updateBoard];
	[button.superview removeFromSuperview];
	self->promotionIx = -1;
	self->displayState = DisplayingGame;
}


// Highlight the position at '(row, column)'
-(void)highlightRow:(int)row andColumn:(int)column inMap:(unsigned long long*)bitmap {
	int ix = row * 8 + column;
	UIButton *button = [self.buttons objectAtIndex:ix];
	if ([self isPieceAtRow:row andColumn:column]) {
		button.layer.borderColor = [UIColor redColor].CGColor;
	} else {
		button.layer.borderColor = [UIColor yellowColor].CGColor;
	}
	// Set the bit in the bitmap
	*bitmap |= (0x1uLL << ix);
}
// Highlight the position at '(row, column)' knowing that it is a capture
-(void)highlightRow:(int)row andColumn:(int)column inMap:(unsigned long long*)bitmap isCapture:(bool)isCapture {
	[self highlightRow:row andColumn:column inMap:bitmap];
	UIButton *button = [self.buttons objectAtIndex:row * 8 + column];
	if (isCapture) {
		button.layer.borderColor = [UIColor redColor].CGColor;
	} else {
		button.layer.borderColor = [UIColor yellowColor].CGColor;
	}
}

// Highlight the valid moves for a rook
-(int)highlightRookMovesFromRow:(int)r andColumn:(int)c inMap:(unsigned long long*)bitmap {
	bool isWhite = [self isWhitePieceAtRow:r andColumn:c];
	int nValids = 0;
	// Search forward and backward
	for (int dr = -1; dr <= 1; dr += 2) {
		for (int subR = r + dr; subR >= 0 && subR < 8; subR += dr) {
			if (![self isPieceAtRow:subR andColumn:c]) {
				[self highlightRow:subR andColumn:c inMap:bitmap];
				++nValids;
			} else {
				if (isWhite ^ [self isWhitePieceAtRow:subR andColumn:c]) {
					// Can be captured
					[self highlightRow:subR andColumn:c inMap:bitmap];
					++nValids;
				}
				// Have to break regardless
				break;
			}
		}
	}
	// Search left and right
	for (int dc = -1; dc <= 1; dc += 2) {
		for (int subC = c + dc; subC >= 0 && subC < 8; subC += dc) {
			if (![self isPieceAtRow:r andColumn:subC]) {
				[self highlightRow:r andColumn:subC inMap:bitmap];
				++nValids;
			} else {
				if (isWhite ^ [self isWhitePieceAtRow:r andColumn:subC]) {
					// Can be captured
					[self highlightRow:r andColumn:subC inMap:bitmap];
					++nValids;
				}
				// Have to break regardless
				break;
			}
		}
	}
	return nValids;
}
// Highlight the valid moves for a bishop
-(int)highlightBishopMovesFromRow:(int)r andColumn:(int)c inMap:(unsigned long long*)bitmap {
	bool isWhite = [self isWhitePieceAtRow:r andColumn:c];
	int nValids = 0;
	int subR, subC;
	for (int rquad = -1; rquad <= 1; rquad += 2) {
		for (int cquad = -1; cquad <= 1; cquad += 2) {
			for (int off = 1; ; ++off) {
				if (((subR = r + off * rquad) >= 0 && subR < 8) && ((subC = c + off * cquad) >= 0 && subC < 8)) {
					if (![self isPieceAtRow:subR andColumn:subC]) {
						[self highlightRow:subR andColumn:subC inMap:bitmap];
						++nValids;
					} else {
						if ((isWhite ^ [self isWhitePieceAtRow:subR andColumn:subC])) {
							[self highlightRow:subR andColumn:subC inMap:bitmap];
							++nValids;
						}
						// Break regardless
						break;
					}
				} else {
					// Move is out of bounds
					break;
				}
			}
		}
	}
	return nValids;
}

// Highlight the valid moves for the piece at 'ix', and return the number of valid moves
-(int)highlightValidMovesFrom:(int)ix inMap:(unsigned long long*)bitmap {
	// Correct it to a lowercase character
	char piece = self->state.board[ix];
	bool isWhite = false;
	if (piece >= 'A' && piece <= 'Z') {
		isWhite = true;
		piece -= 'A' - 'a';
	}

	// De-highlight all valid moves
	[self clearHighlighting];
	*bitmap = 0x0uLL;

	int nValids = 0;

	// The 'forward' direction of the row indices, which is -1 for white and 1 for black
	int forward = isWhite ? -1 : 1;
	int r = ix >> 3, c = ix % 8;
	switch (piece) {
		case 'p':
			// A pawn
			// They can move forward by one
			if (![self isPieceAtRow:r + forward andColumn:c]) {
				[self highlightRow:r + forward andColumn:c inMap:bitmap];
				++nValids;
				// Check for opening double move (if the first spot was clear)
				if (r == (isWhite ? 6 : 1)) {
					if (![self isPieceAtRow:r + 2 * forward andColumn:c]) {
						[self highlightRow:r + 2 * forward andColumn:c inMap:bitmap];
						++nValids;
					}
				}
			}
			// Check the diagonal captures
			if ([self isPieceAtRow:r + forward andColumn:c - 1]
				&& (isWhite ^ [self isWhitePieceAtRow:r + forward andColumn:c - 1])) {
				[self highlightRow:r + forward andColumn:c - 1 inMap:bitmap];
				++nValids;
			}
			if ([self isPieceAtRow:r + forward andColumn:c + 1]
				&& (isWhite ^ [self isWhitePieceAtRow:r + forward andColumn:c + 1])) {
				[self highlightRow:r + forward andColumn:c + 1 inMap:bitmap];
				++nValids;
			}
			// Check _en passant_-able captures
			if (self->state.enPassantableIx != -1) {
				int enR = self->state.enPassantableIx >> 3, enC = self->state.enPassantableIx & 0x7;
				if (r == enR && c - 1 == enC
					&& [self isPieceAtRow:enR andColumn:enC] && (isWhite ^ [self isWhitePieceAtRow:enR andColumn:enC])) {
					[self highlightRow:enR + forward andColumn:enC inMap:bitmap	isCapture:true];
					++nValids;
				}
				if (r == enR && c + 1 == enC
					&& [self isPieceAtRow:enR andColumn:enC] && (isWhite ^ [self isWhitePieceAtRow:enR andColumn:enC])) {
					[self highlightRow:enR + forward andColumn:enC inMap:bitmap	isCapture:true];
					++nValids;
				}
			}
			break;
		case 'r':
			// Rooks
			nValids += [self highlightRookMovesFromRow:r andColumn:c inMap:bitmap];
			break;
		case 'n':
			// Knights
		{
			int subR, subC;
			for (int rquad = -1; rquad <= 1; rquad += 2) {
				for (int cquad = -1; cquad <= 1; cquad += 2) {
					// (1,2)
					if (((subR = r + rquad) >= 0 && subR < 8) && ((subC = c + 2 * cquad) >= 0 && subC < 8)
						&& (![self isPieceAtRow:subR andColumn:subC] || (isWhite ^ [self isWhitePieceAtRow:subR andColumn:subC]))) {
						[self highlightRow:subR andColumn:subC inMap:bitmap];
						++nValids;
					}
					// (2,1)
					if (((subR = r + 2 * rquad) >= 0 && subR < 8) && ((subC = c + cquad) >= 0 && subC < 8)
						&& (![self isPieceAtRow:subR andColumn:subC] || (isWhite ^ [self isWhitePieceAtRow:subR andColumn:subC]))) {
						[self highlightRow:subR andColumn:subC inMap:bitmap];
						++nValids;
					}
				}
			}
		}
			break;
		case 'b':
			// Bishops
			nValids += [self highlightBishopMovesFromRow:r andColumn:c inMap:bitmap];
			break;
		case 'q':
			// Queens ... move like rooks plus bishops
			nValids += [self highlightRookMovesFromRow:r andColumn:c inMap:bitmap]
					 + [self highlightBishopMovesFromRow:r andColumn:c inMap:bitmap];
			break;
		case 'k':
			// Kings
		{
			int subR, subC;
			for (int dr = -1; dr <= 1; ++dr) {
				for (int dc = -1; dc <= 1; ++dc) {
					if (dr == 0 && dc == 0) {
						continue;
					}
					if (((subR = r + dr) >= 0 && subR < 8) && ((subC = c + dc) >= 0 && subC < 8)
						&& (![self isPieceAtRow:subR andColumn:subC] || (isWhite ^ [self isWhitePieceAtRow:subR andColumn:subC]))) {
						[self highlightRow:subR andColumn:subC inMap:bitmap];
						++nValids;
					}
				}
			}
			// Check for if castling is possible
			unsigned char castlingBits = [self getCastlingBits];
			if ((castlingBits & 0x1u) != 0) {
				// The king has not moved
				// - King-side castling is possible if the two spaces to the right of the king are empty
				//   and the 'h' file rook has not moved.
				if ((subC = c + 2) >= 0 && subC < 8 && (castlingBits & 0x4u) != 0
					&& ![self isPieceAtRow:r andColumn:subC - 1]
					&& ![self isPieceAtRow:r andColumn:subC]) {
					[self highlightRow:r andColumn:subC inMap:bitmap];
					++nValids;
				}
				// - Queen-side castling is possible if the two spaces to the left of the king are empty
				//   and the 'a' file rook has not moved.
				if ((subC = c - 2) >= 0 && subC < 8 && (castlingBits & 0x2u) != 0
					&& ![self isPieceAtRow:r andColumn:subC + 1]
					&& ![self isPieceAtRow:r andColumn:subC]) {
					[self highlightRow:r andColumn:subC inMap:bitmap];
					++nValids;
				}
			}
			break;
		}
		default:
			return 0;
	}

	// For each valid move, simulate it and see if it puts us in check, which would be bad
	/*if (nValids > 0) {
		char copy[64];
		for (int i = 0; i < 64; ++i) {
			if ((bitmap & (0x1uLL << i)) != 0) {
				memcpy(
			}
		}
	}*/
	//// Put the bitmap we calculated into position
	//self->lastValidityBitmap = bitmap;
	// Hack and make everything valid
	//self->validityBitmap = 0xffffffffffffffffuLL;
	return nValids;
}


/*
// Implement viewDidLoad to do additional setup after loading the view, typically from a nib.
- (void)viewDidLoad {
    [super viewDidLoad];
}
*/
/*-(void) viewDidAppear:(BOOL)animated{
	[super viewDidAppear:animated];
	[self becomeFirstResponder];
}
-(void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent *)event {
	if (motion == UIEventSubtypeMotionShake) {
		self->lastSelectedPiece = -1;
		self->displayState = 0;
	}
}
- (void)motionEnded:(UIEventSubtype)motion withEvent:(UIEvent*)event {
	if (event.type == UIEventSubtypeMotionShake) {
		self->lastSelectedPiece = -1;
		self->displayState = 0;
		[self clearHighlighting];
	}
}*/


/*
// Override to allow orientations other than the default portrait orientation.
- (BOOL)shouldAutorotateToInterfaceOrientation:(UIInterfaceOrientation)interfaceOrientation {
    // Return YES for supported orientations
    return (interfaceOrientation == UIInterfaceOrientationPortrait);
}
*/

// Checks whether a given square is attackable by white or black
-(bool)isCheckedRow:(int)row andColumn:(int)column byWhite:(bool)byWhite {
	// Calculate the valid move's for 'byWhite's pieces, and, if they ever have 'row' and 'column' in their sights, we know
	int ix = row * 8 + column;
	for (int r = 0; r < 8; ++r) {
		for (int c = 0; c < 8; ++c) {
			if ([self isPieceAtRow:r andColumn:c] && !(byWhite ^ [self isWhitePieceAtRow:r andColumn:c])) {
				unsigned long long bitmap = 0x0uLL;
				if ([self highlightValidMovesFrom:ix inMap:&bitmap] > 0 && (bitmap & (0x1uLL << ix)) != 0) {
					return true;
				}
			}
		}
	}
	return false;
}

- (void)didReceiveMemoryWarning {
	// Releases the view if it doesn't have a superview.
    [super didReceiveMemoryWarning];

	// Release any cached data, images, etc that aren't in use.
}

- (void)viewDidUnload {
	// Release any retained subviews of the main view.
	// e.g. self.myOutlet = nil;
}

// Update the images being displayed on the squares pursuant to the current state of the board
-(void)updateBoard {
	int i = 0;
	for (int r = 0; r < 8; ++r) {
		for (int c = 0; c < 8; ++c) {
			UIImageView *square = [self.squares objectAtIndex:i];
			switch (self->state.board[i]) {
				case 'p':
					square.image = self->blackPawn;
					break;
				case 'r':
					square.image = self->blackRook;
					break;
				case 'n':
					square.image = self->blackKnight;
					break;
				case 'b':
					square.image = self->blackBishop;
					break;
				case 'q':
					square.image = self->blackQueen;
					break;
				case 'k':
					square.image = self->blackKing;
					break;

				case 'P':
					square.image = self->whitePawn;
					break;
				case 'R':
					square.image = self->whiteRook;
					break;
				case 'N':
					square.image = self->whiteKnight;
					break;
				case 'B':
					square.image = self->whiteBishop;
					break;
				case 'Q':
					square.image = self->whiteQueen;
					break;
				case 'K':
					square.image = self->whiteKing;
					break;

				default:
					square.image = nil;
					break;
			}
			++i;
		}
	}
	// And keep the move label up to date
	//self.moveLabel.text = self->whitesMove ? @"Move: White" : @"Move: Black";
	self.moveLabel.text = [[NSString alloc] initWithFormat:@"Move #%d: %@",
						   1 + (self->nMoves >> 1),
						   self->whitesMove ? @"White" : @"Black"];
	// Set the states of the 'Undo' and 'Redo' buttons
	[self.undoButton setHidden:self->nMoves == 0];
	[self.redoButton setHidden:self->nMoves >= self->nCachedMoves];
}

// Add a possible captured piece to the display of materiel
-(void)tallyCaptured:(char)piece {
	if (piece == ' ') {
		// There was no capture
		return;
	}
	bool isWhite = piece >= 'A' && piece <= 'Z';
	NSString *name;
	UIImage *image;
	switch (piece) {
		case 'p':
			image = self->blackPawn;
			name = @"BlackPawn.png"; break;
		case 'P':
			image = self->whitePawn;
			name = @"WhitePawn.png"; break;
		case 'r':
			image = self->blackRook;
			name = @"BlackRook.png"; break;
		case 'R':
			image = self->whiteRook;
			name = @"WhiteRook.png"; break;
		case 'n':
			image = self->blackKnight;
			name = @"BlackKnight.png"; break;
		case 'N':
			image = self->whiteKnight;
			name = @"WhiteKnight.png"; break;
		case 'b':
			image = self->blackBishop;
			name = @"BlackBishop.png"; break;
		case 'B':
			image = self->whiteBishop;
			name = @"WhiteBishop.png"; break;
		case 'q':
			image = self->blackQueen;
			name = @"BlackQueen.png"; break;
		case 'Q':
			image = self->whiteQueen;
			name = @"WhiteQueen.png"; break;
		case 'k':
			image = self->blackKing;
			name = @"BlackKing.png"; break;
		case 'K':
			image = self->whiteKing;
			name = @"WhiteKing.png"; break;
	}
	int originX = 19 + (3 + 16) * [(isWhite ? self.capturedWhites : self.capturedBlacks) count];
	int originY = /*375*/ 360 + (isWhite ? 26 : 0);
	UIImageView *newSlot = [[UIImageView alloc] initWithFrame:CGRectMake(originX, originY, 16, 16)];
	newSlot.image = image;
	[self.view addSubview:newSlot];
	[(isWhite ? self.capturedWhites : self.capturedBlacks) addObject:newSlot];
}

// The 'Undo' button was clicked
-(IBAction)btnUndoClicked:(id)sender {
	if (self->displayState != DisplayingGame) {
		// Can't 'Undo' from this state
		return;
	}
	if (self->nMoves > 0) {
		// Restore the last saved state
		BoardState last = self->history[--self->nMoves];

		// Check if we need to remove something from the captured materiel, which is a spot which changed
		// from one non-space to a different non-space.
		for (int i = 0; i < 64; ++i) {
			if (self->state.board[i] != ' ' && last.board[i] != ' ' && self->state.board[i] != last.board[i]) {
				// 'last[i]' turns out to have been captured, so all we have to do is remove the last image
				// from the appropriate 'captured{color}s' array.
				char captured = last.board[i];
				NSMutableArray *array = captured >= 'A' && captured <= 'Z' ? self.capturedWhites : self.capturedBlacks;
				UIImage *slot = [array lastObject];
				[slot removeFromSuperview];
				[array removeLastObject];
				[slot release];
				break;
			}
		}

		// Copy into the current state
		memcpy(&self->state, &last, sizeof(BoardState));
		self->lastValidityBitmap = 0x0uLL;
		self->lastSelectedPiece = -1;
		self->selectionState = 0;
		self->whitesMove ^= true;
		[self clearHighlighting];
		[self updateBoard];
	}
}
// Whether the 'Redo' button was clicked
-(IBAction)btnRedoClicked:(id)sender {
	if (self->displayState != DisplayingGame) {
		// Can't 'Undo' from this state
		return;
	}
	if (self->nMoves < self->nCachedMoves) {
		// Restore the previous move
		BoardState next = self->history[++self->nMoves];

		// Check if we need to add something to the captured materiel, which is a spot which changed
		// from one non-space to a different non-space.
		for (int i = 0; i < 64; ++i) {
			if (self->state.board[i] != ' ' && next.board[i] != ' ' && self->state.board[i] != next.board[i]) {
				// 'next[i]' turns out to have been captured, so all we have to do is remove the last image
				// from the appropriate 'captured{color}s' array.
				[self tallyCaptured:self->state.board[i]];
				break;
			}
		}

		// Copy into the current state
		memcpy(&self->state, &next, sizeof(BoardState));
		self->lastValidityBitmap = 0x0uLL;
		self->lastSelectedPiece = -1;
		self->selectionState = 0;
		self->whitesMove ^= true;
		[self clearHighlighting];
		[self updateBoard];
	}
}


- (void)dealloc {
	//free(self->state);
	for (UILabel *label in self.squares) {
		[label release];
	}
	free(self->history);
	[self.squares release];
    [super dealloc];
}

@end
