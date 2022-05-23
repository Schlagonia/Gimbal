//SPDX-License-Identifier: Unlicense
pragma solidity >=0.6.2;

// Part: ISwapperEnabled

interface ISwapperEnabled {
  event TradeFactorySet(address indexed _tradeFactory);

  function tradeFactory() external returns (address _tradeFactory);

  function setTradeFactory(address _tradeFactory) external;

  function createTrade(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    uint256 _deadline
  ) external returns (uint256 _id);

  function executeTrade(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage
  ) external returns (uint256 _receivedAmount);

  function executeTrade(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    bytes calldata _data
  ) external returns (uint256 _receivedAmount);


  function cancelPendingTrades(uint256[] calldata _pendingTrades) external;
}


// Part: ITradeFactoryExecutor

interface ITradeFactoryExecutor {
  event SyncTradeExecuted(
    address indexed _strategy,
    address indexed _swapper,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    bytes _data,
    uint256 _receivedAmount
  );

  event AsyncTradeExecuted(uint256 indexed _id, uint256 _receivedAmount);

  event AsyncTradeExpired(uint256 indexed _id);

  event SwapperAndTokenEnabled(address indexed _swapper, address _token);

  function approvedTokensBySwappers(address _swapper) external view returns (address[] memory _tokens);

  function execute(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    bytes calldata _data
  ) external returns (uint256 _receivedAmount);

  function execute(uint256 _id, bytes calldata _data) external returns (uint256 _receivedAmount);

  function expire(uint256 _id) external returns (uint256 _freedAmount);
}

// Part: ITradeFactoryPositionsHandler

interface ITradeFactoryPositionsHandler {
  struct Trade {
    uint256 _id;
    address _strategy;
    address _swapper;
    address _tokenIn;
    address _tokenOut;
    uint256 _amountIn;
    uint256 _maxSlippage;
    uint256 _deadline;
  }

  event TradeCreated(
    uint256 indexed _id,
    address _strategy,
    address _swapper,
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    uint256 _deadline
  );

  event TradeCanceled(address indexed _strategy, uint256 indexed _id);

  event TradesCanceled(address indexed _strategy, uint256[] _ids);

  event TradesSwapperChanged(address indexed _strategy, uint256[] _ids, address _newSwapper);

  function pendingTradesById(uint256)
    external
    view
    returns (
      uint256 _id,
      address _strategy,
      address _swapper,
      address _tokenIn,
      address _tokenOut,
      uint256 _amountIn,
      uint256 _maxSlippage,
      uint256 _deadline
    );

  function pendingTradesIds() external view returns (uint256[] memory _pendingIds);

  function pendingTradesIds(address _strategy) external view returns (uint256[] memory _pendingIds);

  function create(
    address _tokenIn,
    address _tokenOut,
    uint256 _amountIn,
    uint256 _maxSlippage,
    uint256 _deadline
  ) external returns (uint256 _id);

  function cancelPending(uint256 _id) external;

  function cancelAllPending() external returns (uint256[] memory _canceledTradesIds);

  function setStrategyAsyncSwapperAsAndChangePending(
    address _strategy,
    address _swapper,
    bool _migrateSwaps
  ) external returns (uint256[] memory _changedSwapperIds);

  function changeStrategyPendingTradesSwapper(address _strategy, address _swapper) external returns (uint256[] memory _changedSwapperIds);
}
