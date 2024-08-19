module ListWithCurrent exposing (ListWithCurrent(..), addAfter, addAtEnd, addAtStart, addBefore, fromList, getCurrent, moveBackward, moveForward, setCurrentByPredicate, toList, updateCurrent)


type ListWithCurrent a
    = EmptyListWithCurrent
    | ListWithCurrent (List a) a (List a)



-- Adding Element After the Current Element


addAfter : a -> ListWithCurrent a -> ListWithCurrent a
addAfter element listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            ListWithCurrent [] element []

        ListWithCurrent prev current next ->
            ListWithCurrent prev current (element :: next)



-- Adding Element Before the Current Element


addBefore : a -> ListWithCurrent a -> ListWithCurrent a
addBefore element listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            ListWithCurrent [] element []

        ListWithCurrent prev current next ->
            ListWithCurrent (element :: prev) current next


addAtStart : a -> ListWithCurrent a -> ListWithCurrent a
addAtStart element listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            ListWithCurrent [] element []

        ListWithCurrent prev current next ->
            ListWithCurrent [] element (List.reverse prev ++ (current :: next))


addAtEnd : a -> ListWithCurrent a -> ListWithCurrent a
addAtEnd element listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            ListWithCurrent [] element []

        ListWithCurrent prev current next ->
            ListWithCurrent (List.reverse next ++ (current :: prev)) element []


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


updateCurrent : (a -> a) -> ListWithCurrent a -> ListWithCurrent a
updateCurrent updateFn listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            EmptyListWithCurrent

        ListWithCurrent prev current next ->
            ListWithCurrent prev (updateFn current) next


moveBackward : ListWithCurrent a -> ListWithCurrent a
moveBackward listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            EmptyListWithCurrent

        ListWithCurrent [] current next ->
            -- If there is no previous element, we cannot move backward
            ListWithCurrent [] current next

        ListWithCurrent (prevHead :: prevTail) current next ->
            -- Move the current element to the next list, and the previous head becomes the new current
            ListWithCurrent prevTail prevHead (current :: next)


moveForward : ListWithCurrent a -> ListWithCurrent a
moveForward listWithCurrent =
    case listWithCurrent of
        EmptyListWithCurrent ->
            EmptyListWithCurrent

        ListWithCurrent prev current [] ->
            -- If there is no next element, we cannot move forward
            ListWithCurrent prev current []

        ListWithCurrent prev current (nextHead :: nextTail) ->
            -- Move the current element to the prev list, and the next head becomes the new current
            ListWithCurrent (current :: prev) nextHead nextTail
