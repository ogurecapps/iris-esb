Class Broker.Util.Other Extends %RegisteredObject
{

ClassMethod NowMs() As %Integer
{
    Set h = $NOW()
    Return ($PIECE(h,",",1) * 86400 + $PIECE(h,",",2)) * 1000
}

}
