﻿:namespace ∆Format 
  ⍝ Set to 1  before ⎕FIXing to suppress error trapping and to generate verbose messages...
    DEBUG←0 
  ⍝ SEP: Char that separates text format (⎕FMT) or date-time format (1200 I-beam) from code.
  ⍝ Useful SEP chars are ones that don't appear often in code or formats.
  ⍝ To use in such, they are escaped: for $, \$, etc.
  ⍝ E.g. $ £ % 
    SEP←'$' ⋄ eSEP←'\',SEP   
:SECTION For Documentation, see Section "Documentation" below
  ⍝  ∆F - a modest Python-like APL Array-Oriented∆Format Function
  ⍝
  ⍝  Generate and Return a 1 or 2D Formatted String
  ⍝      string←  [⍺0 [⍺1 ...]] ∆F specification [⍵0 [⍵1 ... [⍵99]]]]
  ⍝
  ⍝  Displays∆Format Help info!
  ⍝      ∆F ⍬
:ENDSECTION For Documentation...

:SECTION Miscellaneous Utilities
⍝ ⍙FLD:  Find a pcre field by name or field number
    ⍙FLD←{N O B L←⍺.(Names Offsets Block Lengths)
        def←'' ⋄ isN←0≠⍬⍴0⍴⍵
        p←N⍳∘⊂⍣isN⊣⍵ ⋄ 0≠0(≢O)⍸p:def ⋄ ¯1=O[p]:def     
        B[O[p]+⍳L[p]]
    }
⍝ GenBalanced: generates a pattern that matches balanced parens or equivalent,
⍝  P ← GenBalanced '()'
⍝  (Default) Recursive, matches balanced delimiters, skipping embedded single-quoted or double-quoted strings.
⍝         skipping embedded SQ strings, DQ strings.
⍝         fails on unbalanced braces, e.g. a single left or right brace.
⍝ Display to be easy to read ;-)
    GenBalanced←{L R←⊂¨'\',¨⍵
        N←⊂'bal',⍕bpCount_ ⋄ bpCount_+←1    ⍝ local N- unique pat name in case several in use
        _p←'(?x) (?<N> '                                            ⍝ Pattern <bal1>: N←'bal1' and L R←'{}'
        _p,←'L'                                                     ⍝ ∘ Match "{", then atomically 1 or more of:
        _p,←'      (?>    (?: \\.)+ | [^LR\\"'']+      '            ⍝     ∘ (\.)+ | [^{}\\''"]+ OR
        _p,←'           | (?: "[^"]*"   )+ | (?: ''[^'']*'')+ '     ⍝     ∘ QT anything QT  OR
        _p,←'           | (?&N)*'                                   ⍝     ∘ bal1 {...} recursively 0 or more times
        _p,←'      )+'                                              ⍝     ∘ Else submatch done. Finally,
        _p,←'R   )'                                                 ⍝ ∘ Match "}"
        ∊N@('N'∘=)⊣∊L@('L'∘=)⊣∊R@('R'∘=)⊣_p  ⍝ Repl. N with bal1 etc., L with \{, R with \}.
    }
    bpCount_←1    ⍝ Use the ctr to generate a unique name balNNN for referencing inside the pattern.
  ⍝ ∆XR: Execute and Replace
  ⍝      Replace names of the form ⍎XXX in a string with its executed value
  ⍝      in the calling context (in string form)...
  ⍝       XXX: An APL name, possibly preceded by a limited set of 
  ⍝            simple string-modifying APL fns: ',∊⊂⊃'
  ⍝       ⍺: caller_NS[=⊃⎕RSI]  [err=1] [count=25]
  ⍝          caller_NS: Where to execute each expression found.  Default is the caller's env.
  ⍝          error:    If 1, signals an error if it can't make the requisite replacements.
  ⍝                    If 0, - if ⍎'my_str' failed, the vector 'my_str' is returned.
  ⍝                          - results of more than one line will be raveled.
  ⍝                          - if it exceeds count, returns current replacement
  ⍝                    Default is 1 (signals error).
  ⍝          count:     How many times to scan the ENTIRE string for replacements. Default is 25.
  ⍝ Note: ∆XR by default uses caller's namespace. Internally, we use ∆P←⎕THIS∘∆XR
    eXRCall←'∆XR: 1st element of ⍺ (caller) must be a namespace.'  
    eXRLoop←'∆XR: looping on runaway replacement strings.'
    eXRExec←{'∆XR: An error occurred executing ⍎"',⍵,'".'}         
    eXRForm←{'∆XR: Result not a single line in ⍎"',⍵,'".'}
    ∆XR←{⍺←⊃⎕RSI
      ⍝ ::LOCAL caller ns, err, cnt
        caller err cnt←3↑⍺,1 25↑⍨¯3+≢⍺           
        9≠⎕NC'caller':⎕SIGNAL∘11 eXRCall
        CondErr←{cnt∘←0 ⋄ ~err:⍺ ⋄ ⍵ ⎕SIGNAL 11}
        cnt{cnt←⍺
          cnt≤0:⍵ CondErr eXRLoop
          S←'⍎([,∊⊂⊃]*[\w∆⍙#⎕]+(?:\.[\w∆⍙#⎕]+)*)'⎕R{f1←⍵ ⍙FLD 1
              0::f1 CondErr eXRExec f1
              1=≢r←⎕FMT caller.⍎f1:,r
              (∊r,' ')CondErr eXRForm f1
          }⍠('UCP' 1)⊣⍵
          ⍵≡S:S ⋄ '⍎'(~∊)S:S ⋄ (cnt-1)∇ S
        }⍵
    }
    ∆P←⎕THIS∘∆XR
  ⍝ ⍺ ∆JOIN ⍵:  Treat ⍺, ⍵ each as a matrix and attach ⍺ to the LEFT of ⍵, adding ROWS to ⍺ or ⍵ as needed..
    ∆JOIN←{
        rightHt rightWid←⍴right←⎕FMT ⍵ ⋄ 0=≢⍺:right
        leftHt leftWid←⍴left←   ⎕FMT ⍺ ⋄ MaxHt←leftHt⌈rightHt
        (MaxHt leftWid↑left),(MaxHt rightWid↑right)
    }
  ⍝ ⍺ ∆OVER ⍵:  Treat ⍺, ⍵ each as a matrix and attach ⍺ OVER (ON TOP OF) ⍵, adding COLUMNS to ⍺ or ⍵ as needed..
    ∆OVER←{
        topHt topWid←⍴top←⎕FMT ⍺ ⋄ 0=≢⍵:top
        botHt botWid←⍴bottom←⎕FMT ⍵
        center←0.5×topWid-botWid
        topWid<botWid:((⌈center)⌽topHt botWid↑top)⍪bottom
        top⍪((⌈-center)⌽botHt topWid↑bottom)
    }
  ⍝ Pad:  strM2 ← [char] (pad Pad how) strM
  ⍝ strM: a string in matrix form
  ⍝ char: a single pad char
  ⍝ pad:  non-negative number
  ⍝ how:  L|C|R - left (pad right), center, right (pad left). Do not truncate.
  ⍝       l|c|r - ditto, but truncate if pad is < current width.
  ⍝       Default (' '): Center.
  ⍝ Returns strM2: <strM> padded or truncated as requested.
    Pad←{
        ⍺←' ' ⋄ char pad how strM←⍺ ⍺⍺ ⍵⍵ ⍵
        1≠≢char:11 ⎕SIGNAL⍨'The padding must be exactly one character.'
        wid←⊃⌽⍴strM←⎕FMT strM
        (how∊'LRC ')∧pad≤wid:strM
        strM pad←pad{
            how∊'Ll':(⍺↑[1]⍵)(wid-⍺) ⋄ how∊'Rr':((-⍺)↑[1]⍵)(⍺-wid)
            (⍺↑[1]p↑[1]⍵)(0.5×wid-⍺)⊣p←-⌊0.5×wid+⍺
        }strM
        ' '=char:strM
        pad{
            how∊'Ll':strM⊣(⍺↑[1]strM)←char ⋄ how∊'Rr':strM⊣(⍺↑[1]strM)←char
            ((0⌊⌊⍺)↑[1]strM)←char ⋄ ((0⌈⌊-⍺)↑[1]strM)←char
            strM
        }strM
    }
    ∇ ns←FORMAT_LIB
      ns←⎕THIS.PMSLIB
    ∇
    ∇ FORMAT_HELP
      ⍝:IF 0=⎕NC '_HELP'
          _HELP← '^\h*⍝H(.*)' ⎕S '\1'⊣⎕SRC ⎕THIS 
      ⍝:ENDIF
      ⎕ED⍠('ReadOnly' 0)&'_HELP'
    ∇   
  :ENDSECTION Miscellaneous Utilities

  :SECTION Global Declarations
    ⎕FX '{msg}←DSay msg' ':IF DEBUG ⋄ ⎕←''>>> '',msg ⋄ :ENDIF'
    DSay 'DEBUG is active'
  ⍝ ⎕PATH←1↓∊' ',¨∪' '(≠⊆⊢) ⎕PATH,' ',⍕PMSLIB
    DSay '⎕PATH←',⎕PATH
    ⎕IO←0
    CR←⎕UCS 13  ⋄ DQ SQ←'"'''

  ⍝ Pseudo-format strings specs:
  ⍝     Strings of the form {specs: expression}
  ⍝ In place of APL  ('specs' ⎕FMT expression), we have shorthand
  ⍝       {specs:   expression}.
  ⍝ E.g.  {I5,F4.2: ivec fvec}
  ⍝ fmtFullP matches the specs and following colon.
  ⍝ Fmt Patterns: < >, ⊂ ⊃, ⎕ ⎕ or ¨ ¨ by APL ⎕FMT rules (no embedded matching delims).
  ⍝
  ⍝ Special pseudo-format spec extensions
  ⍝    Lnn, Cnn, Rnn, as in
  ⍝    {C15,I5,F4.2: ivec fvec}, which centers the result of ('I5,F4.2' ⎕FMT ivec fvec)
  ⍝ Must be first (or only) specification given, with optional comma following.
  ⍝    Lnn: obj on left, padded on right to width nn. Ignored if the object is ≥nn in width.
  ⍝    Rnn: obj on right, padded on left to with nn.   Ditto.
  ⍝    Cnn: obj centered.                              Ditto.
    SPECIAL_Q←'⍞' '<>'  '⊂⊃' '⎕' '¨'      ⍝ (?: ⍞[^⍞]*⍞ | <[^>]> ...)
    fmtQtP←    '(?x)(?:',')',⍨¯3↓∊{L R←⍵ ⋄ L,' [^',R,']* ',R,' | '}¨SPECIAL_Q 
    _qtStrP←   '[^"''\⍎SEP\\]++  | "[^"]*+" | ''[^'']*+'' | \\[\⍎SEP]?+'  
  ⍝ Disallow [⍞<>⊂⊃⎕¨"'] in ⎕FMT prefixes, except within special quotes per se [⍞<>⊂⊃⎕¨].
    _f← '(?ix) ^ (?| ( (?: ⍎_qtStrP )*?               ) ( (?<!\\) \⍎SEP{1,2})  (.*+)  '  ⍝ Date-time code
    _f,←'          | (                                ) (           )  (.*+)  '  ⍝ Simple code
    _f,←'        ) $'
    fmtFullP← ∆P _f

  ⍝ padP:   L<*>25 or L25<*> The entire sequence is followed by a comma or the terminating single colon.
  ⍝         Fields: type, wid, char
    _p1←'(?ix) ^ (?<type> [LCR]) (?<wid> \d+)        (?<char> ⍎fmtQtP?) ,?'
    _p2←'(?ix) ^ (?<type> [LCR]) (?<char> ⍎fmtQtP?)  (?<wid> \d+)       ,?'
    padP←∆P¨_p1 _p2

:ENDSECTION Global Declarations

:SECTION MAIN Routines
    ProcEscapes←{  0=≢⍵: ⍵ ⋄ fmt←⍺=¯1 ⋄ text←⍺=0   ⍝ ⍺? ¯1=fmt, 1=code, 0=text
      escIn←   '\\\\n' '\\n', (fmt∨text)⍴⊂∊'\\(['(text fmt/'⋄{}' eSEP),'])'          
      escOut←  '\\n'   '\r' , (fmt∨text)⍴⊂'\1'                     
      escIn ⎕R escOut⊣⍵
    }
  ⍝ omega type ScanCode format_string
  ⍝ Handle strings of the form <⍵NN, ⍺NN, ⍺⍺, ⍵⍵> in format specs, strings within code, and code outside strings:
  ⍝   type=0:  In format specs:  The value of (⍕NN⊃⍵) will be immediately interpolated into the spec (⎕IO=0).
  ⍝   type=1:  In code outside strings:  The code (⍵⊃⍨NN+⎕IO) will replace ⍵NN (⎕IO-independent).
  ⍝ ∘ Null code is an alias for ⍵⍵ (next ⍵ arg).
  ⍝ ∘ If index N is out of range of alpha or omega, signals an index error.
    ScanCode←{ 
        env isCode←⍺ ⍺⍺     ⍝ env fields: env.(caller alpha omega index)
        '("[^"]*")+|(''[^'']*'')+' '\\([⍵⍺])' '([⍵⍺])(\d{1,2}|\1)'⎕R{  ⍝ ⍵00 to ⍵99 | ⍵⍵ | ⍺⍺
            case←⍵.PatternNum∘=
            case 0:CanonQuotes ⍵ ⍙FLD 0     ⍝ Convert double quote sequences to single quote sequences...
            case 1:⍵ ⍙FLD 1                 ⍝ \⍵ is treated as char ⍵
          ⍝ case 2:                         ⍝ ⍵3, ⍺3, ⍵⍵, ⍺⍺
            isW←'⍵'=f1←⍵ ⍙FLD 1
            f2←{(⊃⍵)∊'⍺⍵':⍕1+env.index[isW] ⋄ ⍵}⍵ ⍙FLD 2   ⍝ If ⍵NN, return NN; if ⍵⍵, return 1+env.index<⍺ or ⍵>
            ix←env.index[isW]←⍎f2 ⋄ alom←isW⊃env.(alpha omega)
            ix≥≢alom:3 ⎕SIGNAL⍨(⍵ ⍙FLD 0),' out of range'
            isCode:'(',f1,'⊃⍨',f2,'+⎕IO)'
            ⍕ix⊃alom
        }{isNull←0=≢⍵~' ' ⋄ isNull∧isCode: '⍵⍵' ⋄ ⍵} ⍵
    }
  ⍝ str2 ← CanonQuotes str
  ⍝ Convert strings of form "..." to '...', handling internal " and ' chars.
    CanonQuotes←{
        DQ≠1↑⍵:⍵ ⋄ SQ,SQ,⍨{⍵/⍨1+SQ=⍵}{⍵/⍨~(DQ,DQ)⍷⍵}1↓¯1↓⍵
    }
  ⍝ codeStr2 ← env ExecCode codeString
  ⍝     codeString:  'fmtString : code' |  'date_time_string :: code' | 'code'
  ⍝ ∘ Executes <code> according to the prefix: fmtString (⎕FMT) or the date_time_string (1200⌶) and
  ⍝   any justification specs (L10, C20¨*¨, etc.).
  ⍝ ∘ Returns the ⎕FMTed result (always a char matrix) or ⎕SIGNALs an error.
  ⍝ ∘ Calls <ScanCode> on the prefix and the code itself.
    ExecCode←{
        env code←⍺ ⍵     ⍝ env fields: env.(caller alpha omega index)
        6⍴⍨~DEBUG::⎕SIGNAL/⎕DMX.(EM EN)⊣⎕←'Error executing code: ',code 
      ⍝ Handle omegas
      ⍝ Find formatting prefix, if any
        (pfx separators code)←{   ⍝ Speeds up ⎕R when no : exists at all!
            SEP(~∊)code:'' ''⍵ ⋄ 3↑(fmtFullP ⎕R'\1\n\2\n\3'⊣⊆⍵),⊂''    ⍝ {L15:} => 'L15' ':' ''
        }code
    
      ⍝ KLUDGE: treat \{ and \} as { } in ⊂...⊃-style ⎕FMT expressions. Weakness of using ⎕R for parsing.
        pfx←fmtQtP ⎕R{f0/⍨~⊃∨/'\{' '\}'⍷¨⊂f0←⍵ ⍙FLD 0}⊣pfx
    
        pfx← env(0 ScanCode)pfx              ⍝ 0: ~isCode
        code←env(1 ScanCode)code             ⍝ 1:  isCode
    
      ⍝ Spacing and Justification Pseudo-⎕FMT specs: L20 C20 R20 etc...
      ⍝    pattern: [LCRlcr] (ddd⍞c⍞ | ⍞c⍞ddd) ,?   
      ⍝           ⍞ is any ⎕FMT delim;
      ⍝           c is any single char.
      ⍝ Set locals: pfx; padTYpe, padWid, padChar
        padType padWid padChar←' ' 0 ' '
        pfx←padP ⎕R{t w c←⍵ ⍙FLD¨'type' 'wid' 'char'
            padType padWid padChar∘←t(⍎w)' '
            0=≢c:'' ⋄ padChar∘←1↓¯1↓c ⋄ ''
        }pfx
    
      ⍝ ∆Format codestring <code> executed according to three formatting options...
      ⍝ 1] If prefix <pfx> is null or all blanks
      ⍝    and there is one colon,   call monadic:   
      ⍝          ⎕FMT code
      ⍝    and there are two separators, call: 
      ⍝         '%ISO%' (1200)⌶)code     ⍝ ISO std date-time format.
      ⍝ OTHERWISE...
      ⍝ 2] If there is one separator,    call: pfx ⎕FMT code
      ⍝ 3] If there are two separators,  call: ⎕FMT pfx (1200⌶)code...
        notDT←2≠≢separators 
      ⍝ Is the pfx present? Yes, return it sans leading blanks, after handling Escapes...
      ⍝ If not, (a) not a date, return ''; (b) a date, return %ISO% prefix.
        pfx←pfx{×≢⍺~' ': ¯1 ProcEscapes ⍺↓⍨+/∧\' '=⍺ ⋄ notDT: '' ⋄ ⍵}'%ISO%'
        val←pfx{     
            Dt2Str←⍺∘{0 1↓0 ¯1↓⎕FMT ⍺(1200⌶)⍵} 
          ⍝ Select and execute code string in caller env; alpha/omega are caller's ⍺/⍵ 
          ⍝   (unquoted) ⎕NOW -> current date-time 
          ⍝ Double dfn inside dfn needed since code may have ≥1 expressions sep. by '⋄'.
            Case←env∘⍎ ⍵∘{ code←⍺ ⋄  case←⍵∘∊ 
                RNow←'((?:''[^'']*'')+)' '⎕NOW\b' ⎕R  '\1' '(1⎕DT⊂⎕TS)'⍠1 ⍝ CASE I
                code← RNow⍣(1∊'⎕NOW'⍷code)⊣code  
                case 0: 'alpha   caller.{   ⎕FMT ⍺{', code,'}⍵}omega'   ⍝ ⎕FMT code      (niladic)      
              ⍝                ↓=pfx
                case 1: 'alpha(⍺ caller.{⍺⍺ ⎕FMT ⍺{', code,'}⍵}) omega' ⍝ pfx ⎕FMT code, ⍺→⍺⍺: pfx       
                case 2: 'alpha   caller.{',           code,'}  omega'   ⍝          code   
            }      
          ⍝                                     ⍝ Pfx? Code? | Call...
            0=≢⍺:           Case 0              ⍝ N    Y     | 0adic ⎕FMT code  - and orig ⍺ ⍵
            notDT:          Case 1              ⍝ Y    Y     | pfx   ⎕FMT code  - ditto
                     Dt2Str Case 2              ⍝ Y/N  Date  | pfx  (1200⌶) dt  - If pfx omitted, is %ISO%
        }1∘ProcEscapes code
        padType∊'lcrLCR':padChar(padWid Pad padType)val                    ⍝ See Pad for details...
        val
    }
:EndSection Main Routines

:SECTION Main Executive
  ⍝ ========= MAIN ∆F Formatting Function
  ⍝ ∆F - Major formatting patterns:
  ⍝    ...P the pattern, ...C the pattern number
  ⍝ Braces: Embedded balanced braces are allowed, as are quoted strings (extended to double-quoted strings).
    addPat←{_patNum+←1 ⋄ fmtPats,←⊂⍵ ⋄ 1: fmtNums,←⍎⍺,'∘←_patNum' }
    fmtPats←fmtNums←⍬ ⋄ _patNum←¯1

    'nextFC' addPat  '\{\h*\}'                        ⍝ Next Omega.
    'endFC'  addPat  '⋄|\{\h*[⍬]\h*\}'                ⍝ End of Field.
    'codeFC' addPat GenBalanced '{}'                  ⍝ Code field.
    'textFC' addPat '(?x) (?: \\. | [^{\\⋄]+ )+'      ⍝ Text Field

  ⍝ ∆F: Main user function
    ∇ text←{leftArgs}∆F rightArgs;env;_
      :Trap 0⍴⍨~DEBUG
          :If rightArgs≡⍬ ⋄ FORMAT_HELP ⋄ :Return ⋄ :EndIf
          text←''
          env←(⊃⎕RSI,#).⎕NS'' ⋄ env.⎕DF '[∆Format]'  ⍝ fields: env.(caller alpha omega index)
           ⋄ env.caller←0⊃⎕RSI ⋄ isNum←{16::0 ⋄ ⍬⍴0⍴⍵}  ⍝ 16:: Handles namespace NONCE ERROR
           ⋄ env.alpha←,{⍵:⍬ ⋄ ⍺←leftArgs ⋄ 1<⍴⍴⍺:,⊂⍺ ⋄ ' '≡isNum ⍺:⊆⍺ ⋄ ⍺}900⌶⍬
           ⋄ env.omega←1↓rightArgs←⊆rightArgs
           ⋄ env.index←2⍴¯1    ⍝ "Next" element of alpha ([0]: ⍺, ⍺⍺) and omega ([1]: ⍵, ⍵⍵) to read in ExecCode is index+1.
          _←fmtPats ⎕S{
              case←⍵.PatternNum∘= ⋄ f0←⍵ ⍙FLD 0
              case textFC: 0⍴text∘←text ∆JOIN 0 ProcEscapes f0        ⍝ Any text except {...} or ⋄
              case codeFC: 0⍴text∘←text ∆JOIN env ExecCode 1↓¯1↓f0    ⍝ {[fmt:] code}
              case nextFC: 0⍴text∘←text ∆JOIN env ExecCode'⍵⍵'        ⍝ {}    - Shortcut for '{⍵⍵}'
              case endFC:  ⍬                                          ⍝ ⋄     - End of Field (ends preceding field). Syn: {⍬} {:}
              ⎕SIGNAL/'∆F: Unreachable stmt' 11
          }⊣⊃rightArgs
          text←,⍣(1=≢text)⊣text     ⍝ 1 row matrix quietly converted to a vector...
      :Else
          ⎕SIGNAL/⎕DMX.(EM EN)
      :EndTrap
    ∇ 
:ENDSECTION Main Executive

:SECTION CLEANUP AND EXPORT
    ⎕EX '_' ⎕NL 2 3 4         ⍝ Delete underscore-prefixed vars (those not used at runtime)
    _←0 ⎕EXPORT ⎕NL 3 4
    _←1 ⎕EXPORT ↑'∆F' '∆XR' '∆JOIN' '∆OVER' 'FORMAT_LIB'
:ENDSECTION CLEANUP AND EXPORT

:SECTION Documentation
⍝H ∆F - a modest APL Array-Oriented Format Function Reminiscent of format of Python or C++.
⍝H        formatting multi-dimensional objects, ⎕FMT-compatible numerical fields,
⍝H        and I-Beam 1200-compatible Date-Time objects.
⍝H
⍝H Syntax:
⍝H    string← [⍺0 [⍺1 ... [⍺99]]] ∆F specification [⍵0 [⍵1 ... [⍵99]]]]
⍝H
⍝H    Preview!
⍝H          what←'rain' ⋄ where←'Spain' ⋄ does←'falls' ⋄ locn←'plain'
⍝H          ∆F 'The {what} in {where} {does} mainly on the {locn}.'
⍝H    The rain in Spain falls mainly on the plain.
⍝H        'you' 'know'  ∆F 'The {} in {} {} mainly on the {}, {⍺⍺} {⍺⍺}.' 'rain' 'Spain' 'falls' 'plain'
⍝H    The rain in Spain falls mainly on the plain, you know.
⍝H
⍝H          ∆F'{} produced {I2$ ⍵⍵} units on {Mmm DD, YYYY$$⎕NOW}.' 'We' 25
⍝H     We produced 25 units on Apr 25, 2021.
⍝H
⍝H    Specification: a string containing text, variable names, code, and ⎕FMT specifications, in a single vector string.
⍝H    ∘ In addition to ⍺ or ⍵ (each entire array) or selections therefrom,
⍝H      special variable names within code include
⍝H         ⍺0 (short for (0⊃⍺)), ⍺⍺ (for the next element of ⍺), and
⍝H         ⍵0 (short for (0⊃⍵)), ⍵⍵ (for the next element of ⍵), ... ⍺99 and ⍵99.
⍝H      These may appear one or more times within a Code field and are processed left to right.
⍝H
⍝H  Types of Fields:
⍝H  type:    |    TEXT   |  SIMPLE |    ⎕FMT     |  DATE-TIME   | BLANK  | END OF  |   NEXT ARG
⍝H           |           |  CODE a |   CODE b    |   CODE c     | CODE d | FIELD e |     CODE f
⍝H  format:  | any\ntext | {code}  | {fmt$code}  |  {fmt$$code} | {Lnn$} |    ⋄    | {}  {⍵⍵}  {⍺⍺}
⍝H
⍝H  Special chars in format specifications outside quoted strings:
⍝H    ∘ Escaped chars:  \{  \\ \⋄   - Represented in output as { (left brace), \ (backslash) and ⋄ (lozenge).
⍝H                      \$            dollar sign
⍝H    ∘ Newlines        \n          - In TEXT fields or inside quotes within CODE fields or DATE-TIME specs.
⍝H                                    \n is actually a CR char (Unicode 13), forcing a new APL line in ⎕FMT.
⍝H    ∘ In ⎕FMT field quotes ⎕...⎕, ⊂...⊃, etc., a lone or unbalanced brace { or } must be backslashed, due to limitations
⍝H      in the ∆F parsing algorithm. \ before other chars is treated as expected APL text.
⍝H    Example:
⍝H    ⍝ Good: Single escaped brace  ⍝ Good: Balanced braces       ⍝ Bad! Single unescaped brace
⍝H      ∆F'#1: {¨\{¨,I1$⍳3}'        ∆F'#1: {¨{¨,I1,¨}¨$⍳3}'     ∆F'#1: ¨{¨,I1$⍳3}'
⍝H    #1: {0                        #1: {0}                         SYNTAX ERROR
⍝H        {1                            {1}                           ∆F'#1: {⊂{⊃,I1$⍳3}'
⍝H        {2                            {2}                           ∧
⍝H
⍝H Fields:
⍝H  1.  TEXT field$ Arbitrary text, requiring escaped chars \{ \⍎ and \\ for {⍎\ and \n for newline.
⍝H
⍝H  2.  CODE fields  -- code NOT preceded by a format with a single or double colon
⍝H                      (or preceded by a bare colon with blank or null format)
⍝H   a. SIMPLE CODE FIELD
⍝H      Syntax: {code}   returns the value of the code executed as a 2-d object.
⍝H              {$code}  [ditto]
⍝H      ⍵0..⍵99, ⍵⍵, ⍵, ⍺0..⍺99, ⍺⍺, ⍺ may be used anywhere in a CODE field.
⍝H                  ⍵0 refers to (0⊃⍵); ⍺99 to (99⊃⍺) in ⎕IO=0;
⍝H                  ⍵⍵ refers to the next element of ⍵. If the last (to the left) was ⍵5, then ⍵⍵ is ⍵6.
⍝H                  ⍺⍺ refers to the next element of ⍺. If the last (to the left) was ⍺9, then ⍺⍺ is ⍺10.
⍝H             If used in a format specification, ⍵NN and ⍺NN vars must refer to simple vectors or scalars.
⍝H
⍝H   b. NUMERIC ⎕FMT CODE FIELD (single colon).    See also c. TIME CODE field.
⍝H      Syntax: {[LCR Spec,]prefix$ code}, 
⍝H      Action: Executes <code> and then returns it after formatting via 
⍝H                 prefix ⎕FMT code
⍝H      prefix: any valid ⎕FMT specification 
⍝H              (null or blank specifications are treated as if missing. See SIMPLE CODE FIELDS above)
⍝H
⍝H      LCR Spec: An LCR specification may be the first (foll. by comma) or only specification.
⍝H         It is of the form  "[LCR]nn⎕c⎕," or "[LCR]nn⎕c⎕"
⍝H            LCR: Any of L, C, R, l, c, r.  See below for details.
⍝H            nn:  A non-negative integer indicating the total padding length.
⍝H            ⎕c⎕: Using ⎕FMT quotes (⎕c⎕, ⊂c⊃, etc.) specify <c> a single padding char, if not a blank.
⍝H                 If multiple characters are specified <char>, an error occurs
⍝H
⍝H         Note: {C10⎕⊂⎕,I1$ ⍳3} and {C10,⎕⊂⎕,I1$ ⍳3} differ!
⍝H              ∆F'{C10⎕⊂⎕,I1$ ⍳3}'         ∆F'{C10,⎕⊂⎕,I1$ ⍳3}'
⍝H         ⊂⊂⊂⊂1⊂⊂⊂⊂⊂                            ⊂1
⍝H         ⊂⊂⊂⊂2⊂⊂⊂⊂⊂                            ⊂2
⍝H         ⊂⊂⊂⊂3⊂⊂⊂⊂⊂                            ⊂3
⍝H
⍝H         1. LCR specification:
⍝H             The first "field" may be [no truncate] Lnn, Rnn, or Cnn; or
⍝H                                      [truncate ok] lnn, rnn, or cnn.
⍝H             L, C, or R may pad the associated field, but will NEVER truncate,
⍝H                    even if the field is wider than <nn> characters.
⍝H             l, c, or r will either pad or truncate, depending
⍝H                    on whether the calculated field is wider or narrower than <nn> characters.
⍝H             L/l- object on left side, padded on right.
⍝H               L20: Pad a left-anchored object on right to 20 chars. Do not truncate.
⍝H               l20: Ditto. Truncate as required.
⍝H             C/c- centered.
⍝H               C15: Pad  a field with 8 chars on left and 7 on right. Do not truncate.
⍝H               c15: Ditto. Truncate as required.
⍝H             R/r- right side.
⍝H               R5:  Pad a right-anchored object on left to 5 chars. Do not truncate.
⍝H               r5:  Ditto. Truncate as required.
⍝H
⍝H             Example:
⍝H             ⍝  Delay five seconds, truncating  the result (LEFT) or displaying the result (RIGHT).
⍝H                ∆F '<{l0$⎕DL 0.2}>'                 ∆F '<{L0$⎕DL 0.2}>'  ⍝ Equiv to {⎕DL 0.2}, w/o superfluous L0.
⍝H             <>                                    <0.202345>
⍝H             Examples:                               12345678901234567890
⍝H             #1  ∆F '<{C20,I3$ 1 5⍴⍳5}>'   ==>    <    0  1  2  3  4   >
⍝H             #2  ∆F '<{C2,I5$  1 5 ⍴⍳5}>'  ==>    <    0    1    2    3    4>
⍝H             #3  ∆F '<{C5$"1234567890"}>'  ==>    <1234567890>
⍝H                 ∆F '<{R5$"1234567890"}>'  ==>    <1234567890>
⍝H                 ∆F '<{c5$"1234567890"}>'  ==>    <45678>
⍝H         2.  A field spec may include special ⍵NN- or ⍺NN-positional variables (above), wherever variables are allowed:
⍝H
⍝H         Example:
⍝H             ∆F 'Random: {C⍵0,¨< ¨,F⍵1,⎕ >⎕$ ?3⍴0}' 8 4.2  (or '8' '4.2')
⍝H         Random: < 0.30 >
⍝H                 < 1.00 >
⍝H                 < 0.64 >
⍝H         If a standard format specification is used, APL ⎕FMT rules are followed, treating
⍝H         vectors as 1-column matrices:
⍝H         Example:
⍝H             ∆F 'a: {3↑⎕TS} b: {I4$ 3↑⎕TS} c: {ZI2,⊂/⊃,ZI2,⊂/⊃,I4$ ⍉⍪1⌽3↑⎕TS}'
⍝H         a: 2020 9 6 b: 2020 c: 09/06/2020
⍝H                           9
⍝H                           6
⍝H
⍝H      Code fields and Date-Time specifications may contain the special variable ⎕NOW (case is ignored).
⍝H           ⎕NOW returns (1 ⎕DT ⊂⎕TS), a floating point number.
⍝H      It is most useful in Date-Time specifications (see below). It is only replaced outside single or double quotes.
⍝H         ⍝ Here, we have ⎕NOW in %ISO% format and as a float.
⍝H           ∆F 'Now={$$⎕NOW} Float={⎕NOW}'      
⍝H         Now=2021-04-20T22:53:20 Float=44305.9537
⍝H 
⍝H      Code fields and Date-Time specifications may also contain double-quoted strings "like this"
⍝H      or single-quoted strings entered ''like this'' which appears 'like this'.
⍝H            Valid: "A cat named ""Felix"" is ok!"
⍝H      Quotes entered into other fields like TEXT fields are treated as ordinary text
⍝H      and not processed in this way.
⍝H
⍝H      Example:
⍝H         ∆F '{⍪6⍴"|"} {↑"one\ntwo" "three\nfour" "five\nsix"}'
⍝H      | one
⍝H      | two
⍝H      | three
⍝H      | four
⍝H      | five
⍝H      | six
⍝H
⍝H      Code fields may be arbitrarily complicated. Only the first "prefix$" specification
⍝H      is special:
⍝H      Example (see DATE-TIME CODE fields for a ∆F-style approach):
⍝H         ∆F 'Today is {now←1 ⎕DT ⊂⎕TS ⋄ spec←"__en__Dddd, DDoo Mmmm YYYY hh:mm:ss"⋄ ∊spec(1200⌶)now}.'
⍝H      Today is Sunday, 06th September 2020 17:25:21.
⍝H
⍝H   c. DATE-TIME CODE Field (double-colon), invoking I-beam 1200 (optionally ⎕DT).
⍝H      Syntax:  {time_spec$$ timestamp}  OR  { [LCR-spec,]time_spec$$ timestamp}
⍝H      If time_spec is a specification for formatting dates and times via I-Beam (1200⌶)
⍝H      and timestamp is 1 or more timestamps of the form  (1 ⎕DT ⊂⎕TS) or (1 ⎕DT TS1 TS2 ...)
⍝H      then this returns the timestamp formatted according to the time_spec.
⍝H      - If a single timestamp is passed, a single enclosed string is returned by I-Beam 1200;
⍝H        ∆F automatically discloses single timestamps  (i.e. adds no extra blanks).
⍝H      - Separators within the timestamp need to be in quotes "$" or escaped \$.
⍝H      - If the time_spec is blank, it is treated as '%ISO%' and not ignored (contra I-Beam 1200's default).
⍝H        (⎕FMT specifications, if provided, must not be blank).
⍝H      - In a timestamp code field, the variable ⎕NOW is replaced by (1 ⎕DT ⊂⎕TS).
⍝H            {$$7+⎕NOW} returns the %ISO% time for a week from today.
⍝H        See  examples below.
⍝H      - Restriction: Because of how ∆F parses, two or more contiguous separators within specification text
⍝H        must be double-quoted "$$". 
⍝H
⍝H      Examples
⍝H          now← 1 ⎕DT  ⊂⎕TS         ⍝ ⎕NOW in timestamp code field is (1 ⎕DT ⊂⎕TS) 
⍝H          ∆F '{%ISO%$$now}'         ∆F '{%ISO%$$⎕NOW}'        ∆F '{$$⎕NOW}'  
⍝H      2021-04-18T21:01:16       2021-04-18T21:01:16       2021-04-18T21:01:16
⍝H          ∆F '{tt:mm:ss$$ ⎕NOW} {F12.6$⎕NOW}'
⍝H      03:50:51 44083.660324
⍝H          ∆F'{__da__Dddd, DDoo mmmm YYYY; hh:mm:ss$$⎕NOW}' ⍝ Danish
⍝H      Lørdag, 24. april 2021; 22:08:37
⍝H          ∆F'{__en__Dddd, DDoo mmmm YYYY; hh:mm:ss$$⎕NOW}' ⍝ English (typically, the default)
⍝H      Saturday, 24th april 2021; 22:08:42
⍝H          t1 t2 t3←{⎕TS⊣⎕DL 1+?0}¨1 2 3
⍝H      More Examples
⍝H          ∆F'{I1,⊂. ⊃$⍵⍵}{%ISO%$$1 ⎕DT ⍪⍵ }' (1 2 3) t1 t2 t3    ⍝ Explicit ISO-formatted DATE-TIME
⍝H      1. 2020-09-10T18:30:18
⍝H      2. 2020-09-10T18:30:19
⍝H      3. 2020-09-10T18:30:21
⍝H      ⍝  Presenting a null DATE-TIME specification {$$tt}          ⍝ Default ISO-formatted DATE-TIME
⍝H          tt← ⍪0 0.111+1 ⎕DT ⊂ 2020 9 11 23 13 36 136
⍝H          ∆F '{$$tt}'
⍝H      2020-09-11T23:13:36
⍝H      2020-09-12T01:53:26
⍝H
⍝H   d. BLANK field: {Lnn$⍬} or {Lnn$""}
⍝H      Create a field nn blanks wide, with no other text, where nn is a non-negative integer.
⍝H      Only these cases are allowed: {Lnn$} | {Cnn$} | {Rnn$}. All are equivalent.
⍝H      E.g. to insert 10 blanks between fields:  
⍝H          ∆F'<<<{L10$⍬}>>>'
⍝H      <<<          >>>
⍝H
⍝H   e: END OF FIELD (EOF): ⋄
⍝H      An unescaped lozenge ⋄ terminates the preceding field (if any).
⍝H      Equivalents: Since {⍬} evaluates to an empty (0-width) field, they are synonyms for lozenge as EOF.
⍝H      Example:
⍝H          ∆F 'The cat ⋄is\nisn''t{⍬}here ⋄and\nAND {"It isn''t here either"}'
⍝H      The cat is   here and It isn't here either
⍝H              isn't     AND
⍝H
⍝H   f. NEXT ARG field:  {} is equiv to {⍵⍵}, i.e. the next element in ⍵.
⍝H    - if no explicit {⍵NN} is specified, {} is {⍵0} {⍵1} ....
⍝H    - if {⍵10} is specified, {} to its right selects {⍵11};
⍝H      i.e. after {⍵N},  {} or {⍵⍵} refers to ⍵M, M=N+1.
⍝H    - There is no short-cut for the next alpha field (⍺⍺); it is useful as is.
⍝H    Example:
⍝H      ⍝ 1. A long line.
⍝H         ∆F '{} {} lives at {} in {}, {} in {}' 'John' 'Smith' '424 Main St.' 'Milwaukee' 'WI' 'the USA'
⍝H      John Smith lives at 424 Main St. in Milwaukee, WI in the USA
⍝H      ⍝ 2. A bit of magic to pass format specs and args as peer strings (vectors).
⍝H         info←'John' 'Smith' '424 Main St.' 'Milwaukee' 'WI' 'the USA'
⍝H         ∆F '{} {} lives at {} in {}, {} in {}' {⍵,⍨⊂⍺} info
⍝H      John Smith lives at 424 Main St. in Milwaukee, WI in the USA
⍝H      ⍝ 3. Using ⍺ on the left to pass a list of strings is simple.
⍝H         info  ∆F '{⍺⍺} {⍺⍺} lives at {⍺⍺} in {⍺⍺}, {⍺⍺} in {⍺⍺}'
⍝H      John Smith lives at 424 Main St. in Milwaukee, WI in the USA
⍝H
⍝H Returns: a matrix-format string if 2 or more lines are generated.
⍝H If 1 line, returns it as a vector.
⍝H
⍝H ∆F ⍬  -- Displays∆Format Help info!
    :EndSection Documentation

:EndNamespace
