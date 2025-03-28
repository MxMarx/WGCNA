function [names,RGB,dbg,dtE] = colornames(palette,varargin) %#ok<*ISMAT>
% Convert between RGB values and color names: from RGB to names, or names to RGB.
%
% (c) 2014-2024 Stephen Cobeldick
%
% COLORNAMES matches the input colors (either names or an RGB map) to colors
% from the requested palette. It returns both the color names and RGB values.
%
%%% Syntax:
%  palettes = colornames()
%  names = colornames(palette)
%  names = colornames(palette,RGB)
%  names = colornames(palette,RGB,deltaE)
%  names = colornames(palette,names)
%  names = colornames(palette,name1,name2,...,nameN)
% [names,RGB] = colornames(palette,...)
%
%%% RGB matching:
% * Accepts multiple RGB values in a standard MATLAB Nx3 colormap.
% * Choice of color distance (deltaE) calculation (see Input Arguments
%   below). More info at <https://en.wikipedia.org/wiki/Color_difference>
%   and <https://www.colorwiki.com/wiki/Delta_E:_The_Color_Difference>
% * Note that palettes with sparse colors can produce unexpected matches.
%
%%% Color name matching:
% * Accepts multiple color names, either in one array or as separate inputs.
% * Uppercase/lowercase color name matches, e.g. 'Blue' == 'blue' == 'BLUE'.
% * CamelCase specifies color names with space characters between the words.
% * Palettes with leading indices: may be specified by the number: e.g.: '5'.
% * Palettes with unique initial letter (e.g. Alphabet, MATLAB, and Natural)
%   will match the initial letter (except for 'Black' which is matched by 'K').
% * Flexible name matching. The input name is either:
%    1) matched exactly to a palette name/index/initial.
%    2) used to filter the palette color names for those names containing
%       the same characters (may be nonconsecutive), then the Levenshtein
%       distance is used to select the best matching palette color name.
%
%% Space Characters in Color Names %%
%
% Many palettes use CamelCase in the color names: COLORNAMES will match the
% input names with any character case or spaces between the words, e.g.:
% 'Sky Blue' == 'SKY BLUE' == 'sky blue' == 'SkyBlue' == 'SKYBLUE' == 'skyblue'.
%
% Palettes Foster and xkcd include spaces: clashes occur if the names are
% converted to one case (e.g. lower) and the spaces removed. To make these
% names more convenient to use, camelCase is equivalent to words separated
% by spaces, e.g.: 'EggShell' == 'Egg Shell' == 'egg shell' == 'EGG SHELL'.
% Note this is a different color to 'Eggshell' == 'eggshell' == 'EGGSHELL'.
%
% In xkcd the forward slash ('/') also distinguishes between different
% colors, e.g.: 'Blue/Green' is not the same as 'Blue Green' (== 'BlueGreen').
%
%% Index Numbers in Color Names %%
%
% Palettes with a leading index number (e.g. AppleII, BS381C, CGA, RAL, etc)
% can use just the index number or just the words to select a color, e.g.:
% '5' == 'Blue Flower' == 'BLUE FLOWER' == 'BlueFlower' == '5 Blue Flower'.
% For the palettes with spaces, camelCase is also equivalent to words
% separated by spaces, e.g.: '5BlueFlower' == '5 Blue Flower' == '5 blue flower'
%
%% Initial Letter Color Name Abbreviations %%
%
% Palettes Alphabet, MATLAB, and Natural also match the initial letter to
% the color name (except for 'Black' which is matched by 'k'), e.g.:
% 'B' == 'Blue', 'Y' =='Yellow', 'M' == 'Magenta', 'K' == 'Black'.
%
%% Examples %%
%
% >> palettes = colornames()
% palettes =
%     'Alphabet'
%     'AmstradCPC'
%     'AppleII'
%     'Bang'
%     'BS381C'
%     'CGA'
%     'Crayola'
%     'CSS'
%     'dvips'
%     'Foster'
%     'HTML4'
%     'ISCC'
%     'Kelly'
%     'LeCorbusier'
%     'MacBeth'
%     'MATLAB'
%     'Natural'
%     'OsXCrayons'
%     'PicoMiteVGA'
%     'PptHighlight'
%     'PptStandard'
%     'PWG'
%     'R'
%     'RAL'
%     'Resene'
%     'Resistor'
%     'SherwinWilliams'
%     'SVG'
%     'Tableau'
%     'Thesaurus'
%     'Trubetskoy'
%     'Wada'
%     'Werner'
%     'Wikipedia'
%     'Wolfram'
%     'X11'
%     'xcolor'
%     'xkcd'
%
% >> colornames('Natural') % all color names for one palette
% ans =
%     'Black'
%     'Blue'
%     'Green'
%     'Red'
%     'White'
%     'Yellow'
%
% >> [names,rgb] = colornames('HTML4','blue','RED','Teal','olive')
% names =
%     'Blue'
%     'Red'
%     'Teal'
%     'Olive'
% rgb =
%          0         0    1.0000
%     1.0000         0         0
%          0    0.5020    0.5020
%     0.5020    0.5020         0
%
% >> colornames('HTML4',[0,0.5,1;1,0.5,0]) % default deltaE = CIE94:2
% ans =
%     'Blue'
%     'Red'
%
% >> colornames('HTML4',[0,0.5,1;1,0.5,0],'rgb') % specify deltaE
% ans =
%     'Teal'
%     'Olive'
%
% >> colornames("MATLAB",'c','m','y','k')
% ans =
%     "Cyan"
%     "Magenta"
%     "Yellow"
%     "Black"
%
% >> [names,rgb] = colornames('MATLAB');
% >> compose('%s %g %g %g',char(names),rgb)
% ans =
%     'Black   0 0 0'
%     'Blue    0 0 1'
%     'Cyan    0 1 1'
%     'Green   0 1 0'
%     'Magenta 1 0 1'
%     'Red     1 0 0'
%     'White   1 1 1'
%     'Yellow  1 1 0'
%
%% Input and Output Arguments %%
%
%%% Inputs (**=default):
%  palette = StringScalar or CharRowVector, the name of a supported palette.
%%% The optional input/s can be either color names or RGB values.
%%% Any number of color names can be supplied as either one of:
%  names   = one StringArray or CellOfCharRowVectors, with N color names.
%  name1,name2,..,nameN = N color names as StringScalars or CharRowVectors.
%%% RGB values in a matrix, with optional choice of color-distance deltaE:
%  RGB     = NumericMatrix, size Nx3, each row is an RGB triple (0<=rgb<=1).
%  deltaE  = StringScalar or CharRowVector to select the deltaE method,
%            must be one of 'CIEDE2000', 'DIN99', 'CIE94:1', 'CIE94:2'**,
%            'OKLab', 'CIE76' (aka 'CIELAB'), 'CMC2:1', 'CMC1:1', or 'RGB'.
%
%%% Outputs:
%  palettes = Cell array of char vectors, the names of all supported palettes.
%  names = Array of color names, size Nx1. If <palette> is a string then
%          <names> is string array, otherwise it is a cell of char vectors.
%  rgb   = NumericMatrix, size Nx3. The RGB values corresponding to <names>.
%
% See also COLORNAMES_CUBE COLORNAMES_DELTAE COLORNAMES_SEARCH COLORNAMES_VIEW
% MAXDISTCOLOR BREWERMAP TAB10 LINES ORDEREDCOLORS COLORORDER COLORMAP SET

%% Read Palette Data %%
%
persistent cnData
%
if isempty(cnData)
	cnData = cnMerge(load('colornames.mat'));
end
%
pnc = {cnData.palette};
dtE = {'CIEDE2000','DIN99','CIE94:1','CIE94:2','OKLab','CIE76','CMC2:1','CMC1:1','RGB'};
dbg = cnData;
%
%% Return All Palette Names %%
%
if nargin==0
	if nargout
		names = pnc(:);
		lfh = {@cnNatSort,@cnGammaInv,@cnLab2LCh,@cnLab2DIN99,@cnRGB2HSV,@cnRGB2XYZ,@cnXYZ2Lab,@cnXYZ2OKLab};
		fnm = cellfun(@func2str,lfh,'UniformOutput',0);
		RGB = cell2struct(lfh(:),fnm(:),1);
	else
		pnc(5,:) = {cnData.source};
		pnc(3,:) = {cnData.notes};
		pnc(2,:) = {cnData.count};
		fprintf('%19s %5d  %s\n%27sSource: %s\n',pnc{:});
	end
	return
end
%
%% Retrieve a Palette's Color Names and RGB %%
%
isChRo = @(s) ischar(s) && ndims(s)==2 && size(s,1)==1;
isCofS = @(c) cellfun('isclass',c,'char')&cellfun('ndims',c)==2&cellfun('size',c,1)==1;
%
iss = isa(palette,'string');
palette = cn1s2c(palette);
assert(isChRo(palette),...
	'SC:colornames:palette:NotText',...
	'The first input <palette> must be a string scalar or a char row vector.')
idp = strcmpi(palette,pnc);
tmp = sprintf(' "%s",',pnc{:});
assert(nnz(idp)==1,...
	'SC:colornames:palette:UnknownName',...
	'Palette "%s" is not supported. The palette name must be one of:%s\b.',palette,tmp)
%
cnc = cnData(idp).names(:);
RGB = cnData(idp).rgb;
%
%% Match Input RGB to Palette Colors %%
%
if nargin==1 % return complete palette
	names = cnIf2s(cnc,iss);
	return
elseif isnumeric(varargin{1}) % RGB values
	tmp = sprintf(' "%s",',dtE{:});
	switch nargin
		case 3
			deltaE = cn1s2c(varargin{2});
			assert(isChRo(deltaE),...
				'SC:colornames:deltaE:NotText',[...
				'If the 2nd argument is an RGB map, then the optional 3rd\n'...
				'argument selects the color difference (deltaE) metric.\n'...
				'It must be one of:%s\b.'],tmp)
			idx = cnClosest(RGB,varargin{1},deltaE,tmp);
		case 2
			idx = cnClosest(RGB,varargin{1},'CIE94:2',tmp);
		otherwise
			error('SC:colornames:OneColormapOptionalDeltaE',...
				'One RGB colormap and one optional deltaE input are allowed.')
	end
	RGB = RGB(idx,:);
	cnc = cnc(idx,:);
	names = cnIf2s(cnc,iss);
	return
elseif iscell(varargin{1}) % cell array of character vectors
	assert(nargin==2,...
		'SC:colornames:names:MultipleCellArrays',...
		'Too many inputs: only one cell array of color names is allowed.')
	match = varargin{1}(:);
	assert(all(isCofS(match)),...
		'SC:colornames:names:CellElementNotCharRow',...
		'Every cell element must contain one char row vector (1xN char).')
elseif isa(varargin{1},'string')&&numel(varargin{1})>1 % string array
	assert(nargin==2,...
		'SC:colornames:names:MultipleStringArrays',...
		'Too many inputs: only one string array of color names is allowed.')
	match = cellstr(varargin{1}(:));
else % individual color names
	match = cellfun(@cn1s2c,varargin(:),'UniformOutput',false);
	assert(all(isCofS(match)),...
		'SC:colornames:names:NotText',...
		'Input color names may be string scalars or char row vectors.')
end
%
%% Match Input Names to Palette Color Names %%
%
% Apostrophe characters:
rxq = '[\x27\x60\xB4\x2BC\x2018\x2019\x2032\x2035\xFF07]';
% Hyphen/minus/plus characters:
rxh = '[\x2D\x2010\x2011\x2212\xFE58\xFE63\xFF0D]';
rxp = '[\x2B\xFB29\xFF0B]';
%
if isempty(cnData(idp).regex)
	% Identify uppercase/lowercase letters:
	vec = unique(sprintf('%s',cnc{:}));
	assert(~any(vec==sprintf('\a')),...
		'SC:colornames:matfile:AlarmCharacter',...
		'Palette colornames may not include the alarm character char(7).')
	upc = vec(vec>127&isstrprop(vec,'upper'));
	dnc = vec(vec>127&isstrprop(vec,'lower'));
	% Create regular expressions for splitting CamelCase & Indices:
	ini = {sprintf('[A-Z%s](?=[A-Z%s]+[a-z%s\\s$])',upc,upc,dnc)};
	spl = {sprintf('[a-z%s\\.,](?=[A-Z%s])',dnc,upc)};
	ldi = cnData(idp).index;
	if numel(ldi)
		spl{1,end+1} = sprintf('^(?>(%s))',ldi);
	end
	% Normalize palette names:
	ncn = regexprep(cnc(:),[ini,spl],'$& ');
	ncn = regexprep(ncn,{rxh,rxp,rxq,'\s+'},{'-','+','''',' '});
	% Optional leading index:
	if numel(ldi)
		tkn = regexp(ncn,sprintf('^(%s)\\s*(.+)$',ldi),'once','tokens');
		exa = [vertcat(tkn{:}),ncn];
	else
		exa = ncn;
	end
	% Identify letters with diacritics:
	acc = [305,567,192,193,194,195,196,197,199,200,201,202,203,204,205,206,207,209,210,211,212,213,214,217,218,219,220,221,224,225,226,227,228,229,231,232,233,234,235,236,237,238,239,241,242,243,244,245,246,249,250,251,252,253,255,256,257,258,259,260,261,262,263,264,265,266,267,268,269,270,271,274,275,276,277,278,279,280,281,282,283,284,285,286,287,288,289,290,291,292,293,296,297,298,299,300,301,302,303,304,308,309,310,311,313,314,315,316,317,318,323,324,325,326,327,328,332,333,334,335,336,337,340,341,342,343,344,345,346,347,348,349,350,351,352,353,354,355,356,357,360,361,362,363,364,365,366,367,368,369,370,371,372,373,374,375,376,377,378,379,380,381,382,416,417,431,432,461,462,463,464,465,466,467,468,469,470,471,472,473,474,475,476,478,479,480,481,482,483,486,487,488,489,490,491,492,493,494,496,500,501,504,505,506,507,508,509,510,511,512,513,514,515,516,517,518,519,520,521,522,523,524,525,526,527,528,529,530,531,532,533,534,535,536,537,538,539,542,543,550,551,552,553,554,555,556,557,558,559,560,561,562,563,902,904,905,906,908,910,911,912,938,939,940,941,942,943,944,970,971,972,973,974,979,980,1024,1025,1027,1031,1036,1037,1038,1049,1081,1104,1105,1107,1111,1116,1117,1118,1142,1143,1217,1218,1232,1233,1234,1235,1238,1239,1242,1243,1244,1245,1246,1247,1250,1251,1252,1253,1254,1255,1258,1259,1260,1261,1262,1263,1264,1265,1266,1267,1268,1269,1272,1273,7680,7681,7682,7683,7684,7685,7686,7687,7688,7689,7690,7691,7692,7693,7694,7695,7696,7697,7698,7699,7700,7701,7702,7703,7704,7705,7706,7707,7708,7709,7710,7711,7712,7713,7714,7715,7716,7717,7718,7719,7720,7721,7722,7723,7724,7725,7726,7727,7728,7729,7730,7731,7732,7733,7734,7735,7736,7737,7738,7739,7740,7741,7742,7743,7744,7745,7746,7747,7748,7749,7750,7751,7752,7753,7754,7755,7756,7757,7758,7759,7760,7761,7762,7763,7764,7765,7766,7767,7768,7769,7770,7771,7772,7773,7774,7775,7776,7777,7778,7779,7780,7781,7782,7783,7784,7785,7786,7787,7788,7789,7790,7791,7792,7793,7794,7795,7796,7797,7798,7799,7800,7801,7802,7803,7804,7805,7806,7807,7808,7809,7810,7811,7812,7813,7814,7815,7816,7817,7818,7819,7820,7821,7822,7823,7824,7825,7826,7827,7828,7829,7830,7831,7832,7833,7835,7840,7841,7842,7843,7844,7845,7846,7847,7848,7849,7850,7851,7852,7853,7854,7855,7856,7857,7858,7859,7860,7861,7862,7863,7864,7865,7866,7867,7868,7869,7870,7871,7872,7873,7874,7875,7876,7877,7878,7879,7880,7881,7882,7883,7884,7885,7886,7887,7888,7889,7890,7891,7892,7893,7894,7895,7896,7897,7898,7899,7900,7901,7902,7903,7904,7905,7906,7907,7908,7909,7910,7911,7912,7913,7914,7915,7916,7917,7918,7919,7920,7921,7922,7923,7924,7925,7926,7927,7928,7929,7936,7937,7938,7939,7940,7941,7942,7943,7944,7945,7946,7947,7948,7949,7950,7951,7952,7953,7954,7955,7956,7957,7960,7961,7962,7963,7964,7965,7968,7969,7970,7971,7972,7973,7974,7975,7976,7977,7978,7979,7980,7981,7982,7983,7984,7985,7986,7987,7988,7989,7990,7991,7992,7993,7994,7995,7996,7997,7998,7999,8000,8001,8002,8003,8004,8005,8008,8009,8010,8011,8012,8013,8016,8017,8018,8019,8020,8021,8022,8023,8025,8027,8029,8031,8032,8033,8034,8035,8036,8037,8038,8039,8040,8041,8042,8043,8044,8045,8046,8047,8048,8049,8050,8051,8052,8053,8054,8055,8056,8057,8058,8059,8060,8061,8064,8065,8066,8067,8068,8069,8070,8071,8072,8073,8074,8075,8076,8077,8078,8079,8080,8081,8082,8083,8084,8085,8086,8087,8088,8089,8090,8091,8092,8093,8094,8095,8096,8097,8098,8099,8100,8101,8102,8103,8104,8105,8106,8107,8108,8109,8110,8111,8112,8113,8114,8115,8116,8118,8119,8120,8121,8122,8123,8124,8130,8131,8132,8134,8135,8136,8137,8138,8139,8140,8144,8145,8146,8147,8150,8151,8152,8153,8154,8155,8160,8161,8162,8163,8164,8165,8166,8167,8168,8169,8170,8171,8172,8178,8179,8180,8182,8183,8184,8185,8186,8187,8188,8491];
	rpl = [105,106,65,65,65,65,65,65,67,69,69,69,69,73,73,73,73,78,79,79,79,79,79,85,85,85,85,89,97,97,97,97,97,97,99,101,101,101,101,105,105,105,105,110,111,111,111,111,111,117,117,117,117,121,121,65,97,65,97,65,97,67,99,67,99,67,99,67,99,68,100,69,101,69,101,69,101,69,101,69,101,71,103,71,103,71,103,71,103,72,104,73,105,73,105,73,105,73,105,73,74,106,75,107,76,108,76,108,76,108,78,110,78,110,78,110,79,111,79,111,79,111,82,114,82,114,82,114,83,115,83,115,83,115,83,115,84,116,84,116,85,117,85,117,85,117,85,117,85,117,85,117,87,119,89,121,89,90,122,90,122,90,122,79,111,85,117,65,97,73,105,79,111,85,117,85,117,85,117,85,117,85,117,65,97,65,97,198,230,71,103,75,107,79,111,79,111,439,106,71,103,78,110,65,97,198,230,216,248,65,97,65,97,69,101,69,101,73,105,73,105,79,111,79,111,82,114,82,114,85,117,85,117,83,115,84,116,72,104,65,97,69,101,79,111,79,111,79,111,79,111,89,121,913,917,919,921,927,933,937,953,921,933,945,949,951,953,965,953,965,959,965,969,978,978,1045,1045,1043,1030,1050,1048,1059,1048,1080,1077,1077,1075,1110,1082,1080,1091,1140,1141,1046,1078,1040,1072,1040,1072,1045,1077,1240,1241,1046,1078,1047,1079,1048,1080,1048,1080,1054,1086,1256,1257,1069,1101,1059,1091,1059,1091,1059,1091,1063,1095,1067,1099,65,97,66,98,66,98,66,98,67,99,68,100,68,100,68,100,68,100,68,100,69,101,69,101,69,101,69,101,69,101,70,102,71,103,72,104,72,104,72,104,72,104,72,104,73,105,73,105,75,107,75,107,75,107,76,108,76,108,76,108,76,108,77,109,77,109,77,109,78,110,78,110,78,110,78,110,79,111,79,111,79,111,79,111,80,112,80,112,82,114,82,114,82,114,82,114,83,115,83,115,83,115,83,115,83,115,84,116,84,116,84,116,84,116,85,117,85,117,85,117,85,117,85,117,86,118,86,118,87,119,87,119,87,119,87,119,87,119,88,120,88,120,89,121,90,122,90,122,90,122,104,116,119,121,383,65,97,65,97,65,97,65,97,65,97,65,97,65,97,65,97,65,97,65,97,65,97,65,97,69,101,69,101,69,101,69,101,69,101,69,101,69,101,69,101,73,105,73,105,79,111,79,111,79,111,79,111,79,111,79,111,79,111,79,111,79,111,79,111,79,111,79,111,85,117,85,117,85,117,85,117,85,117,85,117,85,117,89,121,89,121,89,121,89,121,945,945,945,945,945,945,945,945,913,913,913,913,913,913,913,913,949,949,949,949,949,949,917,917,917,917,917,917,951,951,951,951,951,951,951,951,919,919,919,919,919,919,919,919,953,953,953,953,953,953,953,953,921,921,921,921,921,921,921,921,959,959,959,959,959,959,927,927,927,927,927,927,965,965,965,965,965,965,965,965,933,933,933,933,969,969,969,969,969,969,969,969,937,937,937,937,937,937,937,937,945,945,949,949,951,951,953,953,959,959,965,965,969,969,945,945,945,945,945,945,945,945,913,913,913,913,913,913,913,913,951,951,951,951,951,951,951,951,919,919,919,919,919,919,919,919,969,969,969,969,969,969,969,969,937,937,937,937,937,937,937,937,945,945,945,945,945,945,945,913,913,913,913,913,951,951,951,951,951,917,917,919,919,919,953,953,953,953,953,953,921,921,921,921,965,965,965,965,961,961,965,965,933,933,933,933,929,969,969,969,969,969,927,927,937,937,937,65];
	fux = @(c)sprintf('[%c%c]',rpl(acc==c),c); %#ok<NASGU>
	% Regular expression:
	rgx = regexprep(ncn,'\S','$&\a'); % alarm after each non-whitespace character.
	rgx = regexptranslate('escape',rgx);
	rgx = regexprep(rgx,'\a','?'); % replace alarm to make all characters optional.
	rgx = regexprep(rgx,'\s+','\\s*'); % optional whitespace characters.
	rgx = regexprep(rgx,'(G|g)\?r\?[ae]\?y\?','$1?r?[ae]?y?'); % gray|grey.
	rgx = regexprep(rgx,'(O|o)\?c\?(h\?)?(e\?r\?|r\?e\?)','$1?c?h?(e?r?|r?e?)'); % ocer|ocher|ochre.
	rgx = regexprep(rgx,sprintf('[%s]',char(acc)),'${fux($&)}'); % optional diacritics.
	% Initial letters:
	inl = regexpi(ncn,sprintf('[A-Z%s]',upc),'match','once');
	idb = strcmpi(ncn,'BLACK') & ~any(strcmpi('K',inl));
	inl(idb) = {'K'};
	if numel(unique(inl))==numel(inl)
		exa = [inl,exa];
	end
	% Match only the entire string:
	rgx = strcat('^',rgx,'$');
	% Store for next function call:
	cnData(idp).normc = ncn;
	cnData(idp).split = spl;
	cnData(idp).regex = rgx;
	cnData(idp).exact = exa;
else
	ncn = cnData(idp).normc;
	spl = cnData(idp).split;
	rgx = cnData(idp).regex;
	exa = cnData(idp).exact;
end
%
% Normalize input names:
nin = regexprep(match,spl,'$& ');
nin = regexprep(nin,'(^\s+|\s+$)','');
nin = regexprep(nin,{rxh,rxp,rxq,'\s+'},{'-','+','''',' '});
%
% Match input names to palette colornames:
nmm = numel(nin);
idc = cell(nmm,1);
for kk = 1:nmm
	one = nin{kk};
	exr = [];
	if numel(exa)
		[exr,~] = find(strcmpi(one,exa));
	end
	if isempty(exr)
		idc{kk} = find(~cellfun('isempty',regexpi(one,rgx,'once')));
	else
		idc{kk} = -exr(1);
	end
end % using a FOR loop is faster than nested CELLFUN calls.
cnData(idp).match = idc;
%
% Any unmatched input names throw an error:
nmc = cellfun('length',idc);
nm0 = nmc<1;
if any(nm0)
	cnNoMatch(cnc,exa,pnc{idp},nin(nm0),match(nm0))
end
% For input names that match multiple palette regexes, pick the best match:
nm2 = nmc>1;
fh2 = @(s,x)cnPickBest(s,abs(x),ncn);
idc(nm2) = cellfun(fh2,nin(nm2),idc(nm2), 'uni',false);
% Palette indices of matched input names:
idx = abs(vertcat(idc{:}));
%
dbg = cnData;
RGB = RGB(idx,:);
cnc = cnc(idx,:);
names = cnIf2s(cnc,iss);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%colornames
function cnNoMatch(cnc,exa,pnm,nin,rin)
% Find palette color names closest to the input names. Print an error message.
%
try
	cws = matlab.desktop.commandwindow.size;
catch %#ok<CTCH>
	cws = get(0,'CommandWindowSize');
end
%
nmc = numel(cnc);
nme = numel(exa);
nmn = numel(nin);
out = cell(nmn,1);
%
for ii = 1:nmn
	% Identify closest color names:
	edd = nan(nme,1);
	for jj = 1:nme
		edd(jj) = cnEditDist(nin{ii},exa{jj});
	end
	% Stable sort:
	[~,idx] = sort(edd);
	idy = 1+mod(idx-1,nmc);
	[~,idu] = unique(idy);
	idz = idy(sort(idu));
	ccn = cnc(idz);
	% Create formatted text:
	lft = sprintf('%-17s ->',rin{ii});
	vec = 2+numel(lft)+cumsum(4+cellfun('length',ccn));
	idr = find([true;vec(2:end)<=cws(1)],1,'last');
	rgt = sprintf(' "%s",',ccn{1:idr});
	% One text line:
	out{ii} = sprintf('%s',lft,rgt);
end
%
obj = dbstack();
if strcmpi(obj(end).file,'cn_create_doc.m')
	fnh = @(f,p)sprintf('%s("%s")',upper(f),p);
else % command line hypercode
	fnh = @(f,p)sprintf('<a href="matlab:%s(''%s'')">%s("%s")</a>',f,p,upper(f),p);
end
%
% Print error message with color names similar to the requested names:
error('SC:colornames:names:Unmatched',[...
	'Palette "%s" does not contain these colors:%s\b.\n',...
	'Palette color names that are similar to the requested names:\n%s\n',...
	'Call %s to list all color names for that palette,\n',...
	'or %s to view the palette in a 2D list,\n',...
	'or %s to view the palette in a 3D cube,\n',...
	'or %s to interactively search for color names.\n'],...
	pnm, sprintf(' "%s",',rin{:}), sprintf('%s\b.\n',out{:}),...
	fnh('colornames',pnm), fnh('colornames_view',pnm),...
	fnh('colornames_cube',pnm), fnh('colornames_search',pnm))
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnNoMatch
function out = cnPickBest(str,idb,cns)
% Pick the closest color name to match the given input name <str>.
nmb = numel(idb);
edd = nan(nmb,1);
for ii = 1:nmb
	edd(ii) = cnEditDist(str,cns{idb(ii)});
end
[~,ndx] = min(edd); % MIN guarantees exactly one index is returned.
out = idb(ndx);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnPickBest
function d = cnEditDist(S1,S2)
% Wagner-Fischer algorithm to calculate the Levenshtein edit distance.
%
N1 = 1+numel(S1);
N2 = 1+numel(S2);
%
D = nan(N1,N2);
D(:,1) = 0:N1-1;
D(1,:) = 0:N2-1;
%
for r = 2:N1
	for c = 2:N2
		D(r,c) = min([D(r-1,c)+1, D(r,c-1)+1, D(r-1,c-1)+~strcmpi(S1(r-1),S2(c-1))]);
	end
end
d = D(end);
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnEditDist
function idx = cnClosest(rgbP,rgbI,dte,txt)
% Use color difference (deltaE) to identify the closest colors to input RGB values.
%
assert(ndims(rgbI)==2&&size(rgbI,2)==3,...
	'SC:colornames:RGB:NotColormapMatrix',...
	'If the 2nd input is numeric it must be an Nx3 colormap')
assert(isreal(rgbI)&&all(rgbI(:)>=0&rgbI(:)<=1),...
	'SC:colornames:RGB:OutOfRangeOrComplex',...
	'If the 2nd input is numeric all values must be 0<=RGB<=1')
%
%% Calculate the Color Difference (deltaE) %%
%
switch upper(dte)
	case 'OKLAB'
		oklI = cnXYZ2OKLab(cnRGB2XYZ(rgbI));
		oklP = cnXYZ2OKLab(cnRGB2XYZ(rgbP));
		[~,idx] = cellfun(@(v)min(sum(bsxfun(@minus,oklP,v).^2,2)),num2cell(oklI,2));
		return
	case 'RGB'
		[~,idx] = cellfun(@(v)min(sum(bsxfun(@minus,rgbP,v).^2,2)),num2cell(rgbI,2));
		return
end
%
labI = cnXYZ2Lab(cnRGB2XYZ(rgbI));
labP = cnXYZ2Lab(cnRGB2XYZ(rgbP));
%
switch upper(dte)
	case 'DIN99'
		d99I = cnLab2DIN99(labI);
		d99P = cnLab2DIN99(labP);
		[~,idx] = cellfun(@(v)min(sum(bsxfun(@minus,d99P,v).^2,2)),num2cell(d99I,2));
	case {'CIE76','CIELAB','LAB'}
		[~,idx] = cellfun(@(v)min(sum(bsxfun(@minus,labP,v).^2,2)),num2cell(labI,2));
	case 'CIEDE2000'
		[~,idx] = cellfun(@(v)min(sum(cnCIE2k(labP,v,[1,1,1]),2)),num2cell(labI,2));
	case 'CIE94:1'
		[~,idx] = cellfun(@(v)min(sum(cnCIE94(labP,v,[1,1,1],[0,0.045,0.015]),2)),num2cell(labI,2));
	case 'CIE94:2'
		[~,idx] = cellfun(@(v)min(sum(cnCIE94(labP,v,[2,1,1],[0,0.048,0.014]),2)),num2cell(labI,2));
	case 'CMC1:1'
		[~,idx] = cellfun(@(v)min(sum(cnCMClc(labP,v,1,1),2)),num2cell(labI,2));
	case 'CMC2:1'
		[~,idx] = cellfun(@(v)min(sum(cnCMClc(labP,v,2,1),2)),num2cell(labI,2));
	otherwise
		error('SC:colornames:deltaE:UnknownOption',...
			['The 3rd input, color difference (deltaE) metric "%s", is not supported.'...
			'\nThe supported color difference metrics are:%s\b.'],dte,txt)
end
%
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnClosest
function out = cnGammaInv(inp)
% Inverse gamma correction: Nx3 sRGB -> Nx3 linear RGB.
idx = inp > 0.04045;
out = inp / 12.92;
out(idx) = real(((inp(idx) + 0.055) ./ 1.055) .^ 2.4);
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnGammaInv
function XYZ = cnRGB2XYZ(rgb)
% Convert an Nx3 matrix of sRGB values to an Nx3 matrix of XYZ values.
M = [... Standard sRGB to XYZ matrix:
	0.4124,0.3576,0.1805;...
	0.2126,0.7152,0.0722;...
	0.0193,0.1192,0.9505];
% source: IEC 61966-2-1:1999
XYZ = cnGammaInv(rgb) * M.';
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnRGB2XYZ
function Lab = cnXYZ2OKLab(XYZ)
% Convert an Nx3 matrix of XYZ values to an Nx3 matrix of OKLab values.
M1 = [... XYZ to approximate cone responses:
	+0.8189330101, +0.3618667424, -0.1288597137;...
	+0.0329845436, +0.9293118715, +0.0361456387;...
	+0.0482003018, +0.2643662691, +0.6338517070];
M2 = [... nonlinear cone responses to Lab:
	+0.2104542553, +0.7936177850, -0.0040720468;...
	+1.9779984951, -2.4285922050, +0.4505937099;...
	+0.0259040371, +0.7827717662, -0.8086757660];
lms = XYZ * M1.';
lmsp = nthroot(lms,3);
Lab = lmsp * M2.';
% source: <https://bottosson.github.io/posts/oklab/>
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnXYZ2OKLab
function Lab = cnXYZ2Lab(XYZ)
% Convert an Nx3 matrix of XYZ values to an Nx3 matrix of CIELab values.
wpt = [0.95047,1,1.08883]; % D65
delta = 6/29;
xyzr = bsxfun(@rdivide,XYZ,wpt);
idx  = xyzr > delta^3;
fxyz = xyzr/(3*delta^2) + 4/29;
fxyz(idx) = nthroot(xyzr(idx),3);
Lab = [116*fxyz(:,2)-16,...
	500*(fxyz(:,1)-fxyz(:,2)),...
	200*(fxyz(:,2)-fxyz(:,3))];
% source: <https://en.wikipedia.org/wiki/CIELAB_color_space#From_CIEXYZ_to_CIELAB>
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnXYZ2Lab
function Lab99 = cnLab2DIN99(Lab)
% Convert an Nx3 matrix of CIELab values to Nx3 matrix of DIN99 values.
L99 = 105.51 * log(1 + 0.0158*Lab(:,1));
e =     (Lab(:,2).*cosd(16)+Lab(:,3).*sind(16));
f = 0.7*(Lab(:,3).*cosd(16)-Lab(:,2).*sind(16));
G = sqrt(e.^2 + f.^2);
C99 = log(1 + 0.045*G)./0.045;
h99 = atan2(f,e);
a99 = C99 .* cos(h99);
b99 = C99 .* sin(h99);
Lab99 = [L99,a99,b99];
% source: <https://de.wikipedia.org/wiki/DIN99-Farbraum>
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnLab2DIN99
function lch = cnLab2LCh(Lab)
% Convert an Nx3 matrix of CIELab values to Nx3 matrix of LCh values.
lch = Lab;
lch(:,2) = sqrt(sum(Lab(:,2:3).^2,2));
lch(:,3) = cnAtan2D(Lab(:,3),Lab(:,2));
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnLab2LCh
function hsv = cnRGB2HSV(rgb)
% Convert an Nx3 matrix of sRGB triples to an Nx3 matrix of HSV values.
rgb = cnGammaInv(rgb);
[V,X0] = max(rgb,[],2);
C = V - min(rgb,[],2);
N = numel(C);
X1 = N*mod(X0+0,3) + (1:N).';
X2 = N*mod(X0+1,3) + (1:N).';
H = mod(2*(X0-1)+(rgb(X1)-rgb(X2))./C,6);
S = C./V;
S(V==0) = 0;
H(C==0) = 0;
hsv = [60*H,S,V];
% source: <https://en.wikipedia.org/wiki/HSL_and_HSV#From_RGB>
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnRGB2HSV
function LCHsR = cnCIE2k(mat,one, kLCH)
% Convert Nx3 and 1x3 Lab values into Nx4 CIEDE2000 values.
Ca1 = sqrt(sum(mat(:,2:3).^2,2));
Ca2 = sqrt(sum(one(:,2:3).^2,2));
Cb = (Ca1+Ca2)/2;
Lb = (mat(:,1)+one(:,1))/2;
tmp = 1-sqrt(Cb.^7 ./ (Cb.^7 + 25^7));
ap1 = mat(:,2) .* (1+tmp/2);
ap2 = one(:,2) .* (1+tmp/2);
Cp1 = sqrt(ap1.^2 + mat(:,3).^2);
Cp2 = sqrt(ap2.^2 + one(:,3).^2);
Cbp = (Cp1+Cp2)/2;
Cpp = Cp1.*Cp2;
idx = Cpp==0;
hp1 = cnAtan2D(mat(:,3),ap1);
hp2 = cnAtan2D(one(:,3),ap2);
dhp = 180-mod(180+hp1-hp2,360);
dhp(idx) = 0;
Hbp = mod((hp1+hp2)/2 - 180*(abs(hp1-hp2)>180),360);
Hbp(idx) = hp1(idx)+hp2(idx);
T = 1-0.17*cosd(Hbp-30)+0.24*cosd(2*Hbp)+0.32*cosd(3*Hbp+6)-0.2*cosd(4*Hbp-63);
RT = -sind(60*exp(-((Hbp-275)/25).^2)) .* sqrt(Cbp.^7 ./ (Cbp.^7 + 25^7))*2;
SLCH = [(0.015*(Lb-50).^2)./sqrt(20+(Lb-50).^2), 0.045*Cbp, 0.015*Cbp.*T];
dLCH = [(one(:,1)-mat(:,1)), (Cp2-Cp1),...
	2*sqrt(Cpp).*sind(dhp/2)] ./ bsxfun(@times, kLCH, 1 + SLCH);
LCHsR = [dLCH.^2, RT.*prod(dLCH(:,2:3),2)];
% source: <https://en.wikipedia.org/wiki/Color_difference#CIEDE2000>
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnCIE2k
function LCHs = cnCIE94(mat,one, kLCH,K012)
% Convert Nx3 and 1x3 Lab values into Nx3 CIE94 values.
Ca1 = sqrt(sum(mat(:,[2,3]).^2,2));
Ca2 = sqrt(sum(one(:,[2,3]).^2,2));
dHa = sqrt((mat(:,2)-one(:,2)).^2 + (mat(:,3)-one(:,3)).^2 - (Ca1-Ca2).^2);
LCHs = ([(mat(:,1)-one(:,1)), (Ca1-Ca2), dHa] ./ ...
	bsxfun(@times, kLCH, (1 + bsxfun(@times, Ca1, K012)))).^2;
% source: <https://en.wikipedia.org/wiki/Color_difference#CIE94>
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnCIE94
function LCHs = cnCMClc(mat,one, l,c)
% Convert Nx3 and 1x3 Lab values into Nx3 CMC l:c values.
Ca1 = sqrt(sum(mat(:,[2,3]).^2,2));
Ca2 = sqrt(sum(one(:,[2,3]).^2,2));
dHa = sqrt((mat(:,2)-one(:,2)).^2 + (mat(:,3)-one(:,3)).^2 - (Ca1-Ca2).^2);
SL = 0.040975*mat(:,1) ./ (1+0.01765*mat(:,1));
SL(mat(:,1)<16) = 0.511;
SC = 0.0638 * (1 + Ca1./(1+0.0131*Ca1));
h1 = cnAtan2D(mat(:,3),mat(:,2));
F = sqrt(Ca1.^4./(1900+Ca1.^4));
TV1 = [0.36;0.56];
TV2 = [0.4;0.2];
TV3 = [35;168];
idx = 1+(164<=h1 & h1<=345);
T = TV1(idx) + abs(TV2(idx).*cosd(h1+TV3(idx)));
SH = SC .* (F.*T + 1 - F);
LCHs = ([(one(:,1)-mat(:,1)), (Ca2-Ca1), dHa] ./ [l*SL,c*SC,SH]).^2;
% source: <https://en.wikipedia.org/wiki/Color_difference#CMC_l:c_(1984)>
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnCMClc
function ang = cnAtan2D(Y,X)
% ATAN2 with an output in degrees. Note: ATAN2D only introduced R2012b.
ang = mod(360*atan2(Y,X)/(2*pi),360);
ang(Y==0 & X==0) = 0;
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnAtan2D
function ndx = cnNatSort(arr)
% Alphanumeric sort the input text array, returning the sort indices.
[nbr,spl] = regexp(arr,'(+|-)?\d+\.?\d*','match','split');
nmc = cellfun('length',spl);
mxc = max(nmc);
mxr = numel(nmc);
arn = -inf(mxr,mxc);
art = cell(mxr,mxc);
art(:) = {''};
for k = 1:mxr
	arn(k,1:nmc(k)) = sscanf(sprintf(' %s',nbr{k}{:},'-Inf'),'%f');
	art(k,1:nmc(k)) = lower(spl{k});
end
[~,ndx] = sort(art(:,mxc));
for k = mxc-1:-1:1
	[~,idx] = sort(arn(ndx,k),'ascend');
	ndx = ndx(idx);
	[~,idx] = sort(art(ndx,k)); % ascend
	ndx = ndx(idx);
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnNatSort
function out = cnMerge(inp)
% Merge nested scalar structures into one non-scalar structure.
fnr = {'names','rgb'}; % required
fno = {'index','license','source','notes'}; % optional
rgx = '\d+'; % default index regular expression
pnc = fieldnames(inp);
assert(numel(pnc)==numel(unique(lower(pnc))),...
	'SC:colornames:matfile:PaletteNamesNotCaseInsensitiveUnique',...
	'The COLORNAMES.MAT file must contain case-insensitive unique palette names.')
pnc = pnc(cnNatSort(pnc));
out = struct('palette',pnc);
for ii = 1:numel(pnc)
	pn1 = pnc{ii};
	in1 = inp.(pn1);
	assert(isstruct(in1)&&isscalar(in1),...
		'SC:colornames:matfile:PaletteNotScalarStruct',...
		'Palette "%s" must consist of one scalar structure.',pn1)
	fn1 = fieldnames(in1);
	assert(all(ismember(fnr,fn1)),...
		'SC:colornames:matfile:StructMissingFields',...
		'Palette "%s" must contain the fields%s\b.',pn1,sprintf(' <%s>,',fnr{:}))
	tmp = setdiff(fn1,[fnr,fno]);
	assert(isempty(tmp),...
		'SC:colornames:matfile:StructUnsupportedFields',...
		'Palette "%s" unsupported fields%s\b.',pn1,sprintf(' <%s>,',tmp{:}))
	assert(size(in1.rgb,1)==numel(in1.names),...
		'SC:colornames:matfile:NumberOfNamesAndRGB',...
		'Palette "%s" must have an equal number of RGB colors and names.',pn1)
	%
	raw = in1.rgb;
	assert(isnumeric(raw)&&ndims(raw)==2&&size(raw,2)==3&&isreal(raw),...
		'SC:colornames:matfile:NotRealMatrixRGB',...
		'Palette "%s" field <rgb> must be a real Nx3 numeric matrix.',pn1)
	if isinteger(raw)
		rgb = double(raw)/double(intmax(class(raw)));
	else
		rgb = double(raw);
	end
	assert(all(rgb(:)>=0 & rgb(:)<=1),...
		'SC:colornames:matfile:OutOfRangeRGB',...
		'Palette "%s" must contain RGB values such that 0<=RGB<=1',pn1)
	%
	cnc = cellstr(in1.names(:));
	assert(all(cellfun('ndims',cnc)==2&cellfun('size',cnc,1)==1&cellfun('size',cnc,2)>0),...
		'SC:colornames:matfile:NotTextColornames',...
		'Palette "%s" field <names> must be a string array, or a cell array of character vectors.',pn1)
	ndx = cnNatSort(cnc);
	%
	out(ii).raw   = raw(ndx,:);
	out(ii).rgb   = rgb(ndx,:);
	out(ii).count = numel(cnc);
	out(ii).names = cnc(ndx);
	out(ii).regex = [];
	%
	% Optional Indices
	if isfield(in1,fno{1})
		ldi = cn1s2c(in1.(fno{1}));
		if ischar(ldi) % undocumented:
			assert(ndims(ldi)==2&&size(ldi,1)==1)
		else
			assert(isequal(ldi,true)||isequal(ldi,false),...
				'SC:colornames:matfile:NotScalarLogical',...
				'Palette "%s" field <%s> must be a scalar logical.',pn1,fno{1})
		end
	else % automagic detection:
		ldi = ~any(cellfun('isempty',regexp(cnc,sprintf('^(%s)',rgx),'once')));
	end
	if ~ischar(ldi)
		if ldi
			ldi = rgx;
		else
			ldi = [];
		end
	end
	out(ii).(fno{1}) = ldi;
	%
	% Optional Text
	for jj = 2:numel(fno)
		ff = fno{jj};
		if isfield(in1,ff)
			txt = cn1s2c(in1.(ff));
			assert(ischar(txt)&&(isequal(txt,'')||ndims(txt)==2&&size(txt,1)==1),...
				'SC:colornames:matfile:NotValidText',...
				'Palette "%s" field <%s> must consist of a string scalar or a character vector.',pn1,jj)
		else
			txt = '';
		end
		out(ii).(ff) = txt;
	end
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnMerge
function arr = cn1s2c(arr)
% If scalar string then extract the character vector, otherwise data is unchanged.
if isa(arr,'string') && isscalar(arr)
	arr = arr{1};
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cn1s2c
function arr = cnIf2s(arr,mks)
if mks
	arr = string(arr);
end
end
%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%%cnIf2s