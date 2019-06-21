 ∆WHERE←{
   ⍝ Returns a reference to the namespace in which object(s) ⍵ are found, else ⎕NULL
   ⍝ ⍺: [caller [longForm∊0 1=0]]
   ⍝    caller:  the current namespace (or the caller namespace).
   ⍝            a) the current namespace (⍺), b) ⍺.⎕PATH, then c) exhaustively EVERY NAMESPACE in ⎕SE and #
   ⍝    longForm:     1 if type is a long-form alphabetic description
   ⍝                  0 if type is a short-form numeric descriptor (see below)
   ⍝    returning
   ⍝         name where type1     (if longForm=1)
   ⍝         where type2          (if longForm=0)
   ⍝    where
   ⍝         name          the name we are looking for
   ⍝         where         a reference to the namespace where found, else ⎕NULL (if ⍵ not found or invalid)
   ⍝         type1         either a number (type1) or string (type2), depending on longForm (0 or 1)
   ⍝              type1 type2
   ⍝              1.1   caller       item in caller (or other reference) NS (default: caller ns)
   ⍝              1.2   path         item in ⎕PATH, but not current NS
   ⍝              1.3   elsewhere    item found outside current NS and ⎕PATH
   ⍝              0     notFound     item not found
   ⍝             ¯1     invalid       name is invalid
   ⍝ Note that ∆WHERE works with respect to a namespace.
   ⍝ Only functions and operators are searched outside the current namespace.
   ⍝
     ⎕IO←0 ⋄ ⍺←0
     caller longForm←{L R←2↑⍵,0 0 ⋄ 9=⎕NC'L':L R ⋄ 9=⎕NC'R':R L ⋄ (0⊃⎕RSI),L}⍺
     types←(1.1 'caller')(1.2 'path')(1.3 'elsewhere')(0 'not found')(¯1 'invalid')
     fCaller fPath fElsewhere fNotFound fInvalid←longForm⊃¨types

     names←⊆⍵

   ⍝ Utils...
     getRef←{9.1=⍺.⎕NC⊂,⍵:⍺⍎⍵ ⋄ '⎕SE' '#'∊⍨⊂⍵:⍎⍵ ⋄ ⎕NULL}
     scan←{fWhere←⍺⍺
         0=≢⍺:⎕NULL fNotFound
         nc←(ns←0⊃⍺).⎕NC ⍵
         0>nc:⎕NULL fInvalid
         0<nc:ns fWhere
         (1↓⍺)∇ ⍵
     }
   ⍝ refs: from dfns, Returns all namespaces except those in ⍺:skip
     refs←{                              ⍝ Vector of sub-space references for ⍵.
         ⍺←⍬ ⋄ (≢⍺)↓⍺{                   ⍝ default exclusion list.
             ⍵∊⍺:⍺                       ⍝ already been here: quit.
             ⍵.(↑∇∘⍎⍨/⌽(⊂⍺∪⍵),↓⎕NL 9)    ⍝ recursively traverse any sub-spaces.
         }⍵                              ⍝ for given starting ref.
     }

   ⍝ Ignore elements of ⎕PATH that aren't namespaces, ⎕SE or ⍵!
     path←{⍵/⍨⎕NULL≠⍵}caller getRef¨(caller.⎕PATH≠' ')⊆caller.⎕PATH
     alt←∊(⊂# ⎕SE~⍨path,∪caller)refs¨# ⎕SE

     data←caller{
         nc←⍺.⎕NC⍕⍵
         0>nc:⎕NULL fInvalid
         0<nc:⍺ fCaller
         ⎕NULL≠⊃val2←path(fPath scan)⍵:val2
         ⎕NULL≠⊃val2←alt(fElsewhere scan)⍵:val2
         ⎕NULL fNotFound
     }¨names
     ~longForm:data
     data,⍨∘⊂¨names

⍝∇⍣§./∆WHERE.dyalog§0§ 2019 6 21 16 3 45 650 §ôûHuw§0
 }
