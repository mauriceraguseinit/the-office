class AStarNode {
  AStarNode(this.x, this.y, {this.parent});
  final int x;
  final int y;
  double g = 0;
  double h = 0;
  AStarNode? parent;

  double get f => g + h;

  @override
  bool operator ==(Object other) => other is AStarNode && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(x, y);
}
