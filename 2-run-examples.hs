
import System.Command
import System.Exit
import Control.Monad
import Data.List
import Data.String.Utils

skip_rule = "#ignore-embed-eval#"

runTests = zipWithM ( \inp ex ->
  if isInfixOf "(eval" inp && (skip_rule `isInfixOf` inp) then
    putStrLn ("SKIP | " ++ inp ++ " => " ++ ex ++ ", due to " ++ skip_rule)
    >> return True
  else
    do
      Stdout out' <- command [] "./MiniLISP" ["-e",inp]
      let out = init out' -- ignore \n at end
      if (out == ex)
        then putStrLn (":) | " ++ inp ++ " => " ++ ex)
        else putStrLn ("XX | " ++ inp ++ " => " ++ ex ++ ", but got: " ++ out )
      return (out == ex)
  )

testCases =
  takeWhile (/="-- lisp self-interpreter")
  . filter (\x -> length x > 0 && (take 2 x /= "--"))

embedEvalCases = takeWhile (\s -> not (isInfixOf "#ignore-embed-eval-following#" s))

splitLines = lines . replace "\\\n" "" -- use backslash for multi-line expressions

main = do
  inputs <- splitLines <$> readFile "1-examples.in"
  expected <- splitLines <$> readFile "1-examples.out"

  let inps = testCases inputs
      expt = testCases expected

  res1 <- runTests inps expt


  let varname = "expr"
      ruleStart = varname ++ " ->"
      replacementRule = head . filter (isPrefixOf ruleStart) . tails . head . filter (isInfixOf ruleStart) $ inputs
      body = drop (length ruleStart) replacementRule
      embedInEval expr = replace varname expr body

  putStrLn $ "*************\nRepeating tests with lisp self-interpreter: " ++ replacementRule

  res2 <- runTests (map embedInEval (embedEvalCases inps)) expt

  if (and res1 && and res2)
    then putStrLn "*+++ All tests passed! +++*"
    else putStrLn "*XXX Some tests failed! XXX*"
