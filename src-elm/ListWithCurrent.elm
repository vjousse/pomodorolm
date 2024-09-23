module ListWithCurrent exposing (ListWithCurrent(..), fromList, getCurrent, setCurrentByPredicate, toList)


type ListWithCurrent a
    = EmptyListWithCurrent
    | ListWithCurrent (List a) a (List a)



-- Adding Element After the Current Element
-- Adding Element Before the Current Element


fromList : List a -> ListWithCurrent a
fromList list =
    case list of
        [] ->
            EmptyListWithCurrent

        x :: xs ->
            ListWithCurrent [] x xs


toList : ListWithCurrent a -> List a
toList listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            []

        ListWithCurrent prev current next ->
            List.reverse prev ++ (current :: next)


getCurrent : ListWithCurrent a -> Maybe a
getCurrent listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            Nothing

        ListWithCurrent _ current _ ->
            Just current


setCurrentByPredicate : (a -> Bool) -> ListWithCurrent a -> ListWithCurrent a
setCurrentByPredicate predicate listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            EmptyListWithCurrent

        ListWithCurrent prev current next ->
            let
                -- Combine all elements into a single list
                combinedList =
                    List.reverse prev ++ (current :: next)

                -- Find the index of the element that matches the predicate
                matchingIndex =
                    List.indexedMap
                        (\i elem ->
                            if predicate elem then
                                Just i

                            else
                                Nothing
                        )
                        combinedList
                        |> List.filterMap identity
                        |> List.head

                -- Split the combined list at the found index
                ( before, after ) =
                    case matchingIndex of
                        Just idx ->
                            ( List.take idx combinedList, List.drop idx combinedList )

                        Nothing ->
                            ( [], combinedList )

                -- If no match found, use the original list
                -- Update `prev`, `current`, and `next` based on the new position
                ( newPrev, newCurrentAndNext ) =
                    case after of
                        x :: xs ->
                            ( List.reverse before, x :: xs )

                        _ ->
                            ( List.reverse before, after )

                ( newCurrent, newNext ) =
                    case newCurrentAndNext of
                        x :: xs ->
                            ( x, xs )

                        [] ->
                            ( current, [] )
            in
            ListWithCurrent newPrev newCurrent newNext
