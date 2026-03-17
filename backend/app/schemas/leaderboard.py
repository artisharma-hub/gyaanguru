from typing import List, Optional

from pydantic import BaseModel


class LeaderboardPlayer(BaseModel):
    id: str
    name: str
    avatar_color: str
    wins: int
    coins: int
    rank: int


class LeaderboardResponse(BaseModel):
    players: List[LeaderboardPlayer]
    my_rank: Optional[int] = None
